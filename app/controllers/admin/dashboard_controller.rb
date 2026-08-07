class Admin::DashboardController < Admin::BaseController
  def index
    clinic = current_user.clinic

    # Mês selecionado (padrão: mês atual).
    @month = parse_month(params[:month]) || Date.current.beginning_of_month

    # Créditos TOTAIS: todo o crédito (dinheiro real) ainda não usado nas
    # carteiras — inclui os marcados "fora da receita" (já pagos antes); exclui
    # só o promocional. Snapshot — não muda ao trocar o mês.
    @total_credits = Credit.available.where(clinic: clinic)
      .where.not("reason ILIKE ?", "%promocional%")
      .sum(:amount_cents)

    # Receita e crédito atribuídos ao MÊS EM QUE O DINHEIRO ENTROU na conta:
    # pagamentos externos pelo mês do pagamento; crédito pelo mês da COMPRA do
    # crédito (não pelo mês em que é usado).
    @revenue_by_month = revenue_by_month(clinic)
    @credits_by_month = credits_by_month(clinic)

    @monthly_turnos, @monthly_insumos = @revenue_by_month.fetch(@month, [ 0, 0 ])
    @monthly_credits = @credits_by_month.fetch(@month, 0)
    @monthly_revenue = @monthly_turnos + @monthly_insumos + @monthly_credits

    @available_months = months_with_history(clinic)
    @monthly_series   = build_monthly_series(clinic, months: 6)

    # ── Dados dos modais de detalhamento (apenas leitura — não alteram os
    # totais calculados acima; reaproveitam a mesma fonte de dados). ──
    @credit_balances_by_client = credit_balances_by_client(clinic)
    @monthly_extras_purchases  = monthly_extras_purchases(clinic, @month)
    @monthly_turnos_by_client  = monthly_turnos_by_client(clinic, @month)
    @monthly_summary_by_client = monthly_summary_by_client(clinic, @month)
  end

  private

  # Créditos in_revenue (não promo). available_real_credits = só os não usados.
  def real_credits(clinic)
    Credit.where(clinic: clinic, in_revenue: true).where.not("reason ILIKE ?", "%promocional%")
  end

  def available_real_credits(clinic)
    real_credits(clinic).available
  end

  def confirmed_groups(clinic)
    @confirmed_groups ||= BookingGroup.where(clinic: clinic, status: "confirmed").includes(:payments).to_a
  end

  def extras_cents(extras)
    Array(extras).sum { |e| e["price_cents"].to_i * e["quantity"].to_i }
  end

  # { mês(Date) => [turnos_cents, insumos_cents] } — soma de revenue_entries.
  def revenue_by_month(clinic)
    acc = Hash.new { |h, k| h[k] = [ 0, 0 ] }
    revenue_entries(clinic).each do |e|
      acc[e[:month]][0] += e[:turnos_cents]
      acc[e[:month]][1] += e[:insumos_cents]
    end
    acc
  end

  # Mesmo cálculo do revenue_by_month, mas mantendo a referência ao grupo de
  # cada fatia de receita — usado tanto para os totais quanto para os modais
  # de detalhamento por cliente (garante que os valores batam com o dashboard).
  #
  # Cada fonte de pagamento de uma reserva confirmada (Pix/admin OU crédito) é
  # atribuída ao mês em que entrou: pagamento externo pelo paid_at; crédito pela
  # data de COMPRA (created_at). Assim crédito comprado em maio e usado em junho
  # conta em maio.
  def revenue_entries(clinic)
    @revenue_entries ||= begin
      groups = confirmed_groups(clinic)
      off    = Credit.where(used_on_booking_group: groups.map(&:id), in_revenue: false)
                     .group(:used_on_booking_group_id).sum(:amount_cents)
      used_credits = real_credits(clinic).where.not(used_on_booking_group_id: nil)
                                         .group_by(&:used_on_booking_group_id)

      entries = []
      groups.each do |g|
        insumos   = extras_cents(g.extras)
        countable = [ g.total_cents.to_i - off[g.id].to_i, 0 ].max
        next if countable <= 0
        turnos_part = countable - [ insumos, countable ].min

        sources = []
        g.payments.each do |p|
          sources << [ p.paid_at, p.amount_cents.to_i ] if p.paid? && %w[infinitepay admin].include?(p.gateway)
        end
        (used_credits[g.id] || []).each { |cr| sources << [ cr.created_at, cr.amount_cents.to_i ] }
        sources.sort_by! { |date, _| date || Time.at(0) }

        remaining = countable
        sources.each do |date, amount|
          take = [ amount, remaining ].min
          break if take <= 0
          remaining -= take
          month = (date || g.created_at).to_date.beginning_of_month
          t = (take * turnos_part / countable.to_f).round
          entries << { group: g, month: month, turnos_cents: t, insumos_cents: take - t }
        end
      end
      entries
    end
  end

  # Modal "Créditos totais": saldo de crédito disponível, por cliente. Mesmo
  # escopo de @total_credits — a soma dos valores bate com o total exibido.
  def credit_balances_by_client(clinic)
    sums = Credit.available.where(clinic: clinic)
      .where.not("reason ILIKE ?", "%promocional%")
      .group(:user_id).sum(:amount_cents)
    return [] if sums.empty?

    users = User.where(id: sums.keys).index_by(&:id)
    sums.map { |user_id, cents| { user: users[user_id], amount_cents: cents } }
        .sort_by { |h| -h[:amount_cents] }
  end

  # Modal "Insumos do mês": cada compra de insumo paga dentro do mês (uma
  # linha por pagamento com insumos), com o cliente e os itens comprados.
  def monthly_extras_purchases(clinic, month)
    Payment.where(clinic: clinic, status: "paid", paid_at: month.all_month)
      .includes(booking_group: :dentist)
      .order(:paid_at)
      .select { |p| p.extras.present? }
  end

  # Modal "Receita de turnos do mês": reservas com receita de turno no mês,
  # agrupadas por cliente.
  def monthly_turnos_by_client(clinic, month)
    cents_by_group = Hash.new(0)
    revenue_entries(clinic).each do |e|
      next unless e[:month] == month
      cents_by_group[e[:group].id] += e[:turnos_cents]
    end
    cents_by_group.select! { |_, cents| cents.positive? }
    return [] if cents_by_group.empty?

    groups = BookingGroup.where(id: cents_by_group.keys).includes(:dentist, bookings: :availability)
    groups.map { |g| { group: g, dentist: g.dentist, turnos_cents: cents_by_group[g.id] } }
          .sort_by { |h| -h[:turnos_cents] }
  end

  # Modal "Receita total do mês": resumo de consumo por cliente (turnos +
  # insumos + crédito comprado e ainda não usado no mês). Os valores em
  # cents vêm de revenue_entries/credits_by_month — a soma bate exatamente
  # com @monthly_revenue. Os nomes de turnos/insumos são só para exibição.
  def monthly_summary_by_client(clinic, month)
    per_client = Hash.new { |h, k| h[k] = { user: nil, turnos_cents: 0, insumos_cents: 0, credits_cents: 0, turnos: [], insumos: [] } }

    revenue_entries(clinic).each do |e|
      next unless e[:month] == month
      dentist = e[:group].dentist
      entry   = per_client[dentist.id]
      entry[:user] ||= dentist
      entry[:turnos_cents]  += e[:turnos_cents]
      entry[:insumos_cents] += e[:insumos_cents]
    end

    monthly_turnos_by_client(clinic, month).each do |row|
      entry = per_client[row[:dentist]&.id]
      entry[:user] ||= row[:dentist]
      row[:group].bookings.each do |b|
        next unless b.availability
        entry[:turnos] << "#{b.availability.label} — #{I18n.l(b.availability.date, format: '%d/%m')}"
      end
    end

    monthly_extras_purchases(clinic, month).each do |p|
      dentist = p.booking_group.dentist
      entry   = per_client[dentist&.id]
      entry[:user] ||= dentist
      Array(p.extras).each { |e| entry[:insumos] << "#{e['name']} (#{e['quantity']}x)" }
    end

    available_real_credits(clinic).where(created_at: month.all_month)
      .group(:user_id).sum(:amount_cents).each do |user_id, cents|
        entry = per_client[user_id]
        entry[:user] ||= User.find_by(id: user_id)
        entry[:credits_cents] += cents
      end

    return [] if per_client.empty?

    per_client.values
      .map { |v| v.merge(total_cents: v[:turnos_cents] + v[:insumos_cents] + v[:credits_cents]) }
      .select { |v| v[:total_cents].positive? }
      .sort_by { |v| -v[:total_cents] }
  end

  # { mês(Date) => créditos_cents } — crédito real ainda não usado, pelo mês da compra.
  def credits_by_month(clinic)
    available_real_credits(clinic).pluck(:created_at, :amount_cents).each_with_object(Hash.new(0)) do |(created, cents), acc|
      acc[created.to_date.beginning_of_month] += cents.to_i
    end
  end

  def parse_month(value)
    return nil if value.blank?
    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end

  def months_with_history(clinic)
    months = (@revenue_by_month.keys + @credits_by_month.keys + [ Date.current.beginning_of_month ])
    months.uniq.sort.reverse
  end

  def build_monthly_series(clinic, months:)
    today = Date.current
    (0...months).map { |i| (today << i).beginning_of_month }.reverse.map do |start|
      t, i = @revenue_by_month.fetch(start, [ 0, 0 ])
      cr   = @credits_by_month.fetch(start, 0)
      { month: start, turnos: t, insumos: i, credito: cr, total: t + i + cr }
    end
  end
end
