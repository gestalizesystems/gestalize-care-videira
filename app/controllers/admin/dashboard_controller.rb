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
    @manual_by_month  = manual_revenue_by_month(clinic)
    @credits_by_month = credits_by_month(clinic)

    turnos, insumos          = @revenue_by_month.fetch(@month, [ 0, 0 ])
    manual_turnos, manual_insumos = @manual_by_month.fetch(@month, [ 0, 0 ])
    @monthly_turnos  = turnos + manual_turnos
    @monthly_insumos = insumos + manual_insumos
    @monthly_credits = @credits_by_month.fetch(@month, 0)
    @monthly_revenue = @monthly_turnos + @monthly_insumos + @monthly_credits

    @available_months = months_with_history(clinic)
    @monthly_series   = build_monthly_series(clinic, months: 6)

    # ── Dados dos modais de detalhamento (apenas leitura — não alteram os
    # totais calculados acima; reaproveitam a mesma fonte de cálculo). ──
    @credit_balances_by_client = credit_balances_by_client(clinic)
    @monthly_extras_purchases  = monthly_extras_purchases(clinic, @month)
    @monthly_turnos_by_client  = monthly_turnos_by_client(clinic, @month)
    @monthly_summary_by_client = monthly_summary_by_client(clinic, @month)

    # Lista para o autocomplete de cliente no formulário "Adicionar receita".
    @clients_for_autocomplete = clinic.users.where(role: "dentist").order(:name).pluck(:id, :name)
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
  # Cada fonte de pagamento de uma reserva confirmada é atribuída ao mês em
  # que entrou: pagamento externo pelo paid_at; crédito já em carteira pela
  # data de COMPRA do crédito (created_at) — não pelo mês em que é usado.
  #
  # A divisão entre turno/insumo de cada fonte usa o que ela REALMENTE cobriu:
  # todo Payment grava seus próprios insumos no campo `extras` (uma reserva
  # nova, uma compra avulsa de insumo ou uma diferença de troca de turno cada
  # um sabe exatamente o que pagou). Só o crédito já em carteira (sem essa
  # informação) é dividido proporcionalmente pelo que sobrar de cada "pote".
  def revenue_entries(clinic)
    @revenue_entries ||= begin
      groups = confirmed_groups(clinic)
      off    = Credit.where(used_on_booking_group: groups.map(&:id), in_revenue: false)
                     .group(:used_on_booking_group_id).sum(:amount_cents)
      used_credits = real_credits(clinic).where.not(used_on_booking_group_id: nil)
                                         .group_by(&:used_on_booking_group_id)

      entries = []
      groups.each do |g|
        insumos_total = extras_cents(g.extras)
        countable     = [ g.total_cents.to_i - off[g.id].to_i, 0 ].max
        next if countable <= 0
        remaining_insumos = [ insumos_total, countable ].min
        remaining_turnos  = countable - remaining_insumos

        sources = []
        g.payments.each do |p|
          next unless p.paid? && %w[infinitepay admin].include?(p.gateway)
          sources << { date: p.paid_at, amount: p.amount_cents.to_i, known_insumos: extras_cents(p.extras) }
        end
        (used_credits[g.id] || []).each do |cr|
          sources << { date: cr.created_at, amount: cr.amount_cents.to_i, known_insumos: nil }
        end
        sources.sort_by! { |s| s[:date] || Time.at(0) }

        remaining = countable
        sources.each do |s|
          take = [ s[:amount], remaining ].min
          break if take <= 0
          remaining -= take
          month = (s[:date] || g.created_at).to_date.beginning_of_month

          if s[:known_insumos]
            insumos_take = [ s[:known_insumos], remaining_insumos, take ].min
            turnos_take  = take - insumos_take
            if turnos_take > remaining_turnos
              insumos_take += turnos_take - remaining_turnos
              turnos_take   = remaining_turnos
            end
          else
            pool  = remaining_turnos + remaining_insumos
            ratio = pool.positive? ? remaining_turnos / pool.to_f : 0
            turnos_take  = (take * ratio).round
            insumos_take = take - turnos_take
          end

          remaining_turnos  -= turnos_take
          remaining_insumos -= insumos_take
          entries << { group: g, month: month, turnos_cents: turnos_take, insumos_cents: insumos_take }
        end
      end
      entries
    end
  end

  # { mês(Date) => [turnos_cents, insumos_cents] } — lançamentos manuais do admin.
  def manual_revenue_by_month(clinic)
    acc = Hash.new { |h, k| h[k] = [ 0, 0 ] }
    ManualRevenueEntry.where(clinic: clinic).find_each do |e|
      idx = e.category == "turno" ? 0 : 1
      acc[e.month][idx] += e.amount_cents
    end
    acc
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

  # Modal "Insumos do mês": cada compra de insumo paga dentro do mês, mais os
  # lançamentos manuais de insumo — um item por linha em cada card.
  def monthly_extras_purchases(clinic, month)
    rows = Payment.where(clinic: clinic, status: "paid", paid_at: month.all_month)
      .includes(booking_group: :dentist)
      .order(:paid_at)
      .select { |p| p.extras.present? }
      .map do |p|
        dentist = p.booking_group.dentist
        { client_id: dentist&.id, name: dentist&.name || "Cliente removido",
          amount_cents: extras_cents(p.extras),
          items: Array(p.extras).map { |e| "#{e['name']} (#{e['quantity']}x)" },
          manual: false }
      end

    ManualRevenueEntry.for_month(month).where(clinic: clinic, category: "insumo").includes(:client).each do |entry|
      rows << { client_id: entry.client_id, name: entry.client.name, amount_cents: entry.amount_cents,
                items: [ "Lançamento manual" ], manual: true }
    end

    rows.sort_by { |r| -r[:amount_cents] }
  end

  # Modal "Receita de turnos do mês": reservas com receita de turno no mês,
  # mais os lançamentos manuais de turno, agrupados por cliente.
  def monthly_turnos_by_client(clinic, month)
    cents_by_group = Hash.new(0)
    revenue_entries(clinic).each do |e|
      next unless e[:month] == month
      cents_by_group[e[:group].id] += e[:turnos_cents]
    end
    cents_by_group.select! { |_, cents| cents.positive? }

    groups = cents_by_group.empty? ? {} : BookingGroup.where(id: cents_by_group.keys)
      .includes(:dentist, bookings: :availability).index_by(&:id)

    rows = cents_by_group.filter_map do |group_id, cents|
      g = groups[group_id]
      next unless g
      turnos = g.bookings.filter_map { |b| b.availability && "#{b.availability.label} — #{I18n.l(b.availability.date, format: '%d/%m')}" }
      { client_id: g.dentist_id, name: g.dentist.name, turnos_cents: cents, turnos: turnos, manual: false }
    end

    ManualRevenueEntry.for_month(month).where(clinic: clinic, category: "turno").includes(:client).each do |entry|
      rows << { client_id: entry.client_id, name: entry.client.name, turnos_cents: entry.amount_cents,
                turnos: [ "Lançamento manual" ], manual: true }
    end

    rows.sort_by { |r| -r[:turnos_cents] }
  end

  # Modal "Receita total do mês": resumo de consumo por cliente (turnos +
  # insumos + crédito comprado e ainda não usado no mês + lançamentos
  # manuais). Os valores em cents vêm de revenue_entries/credits_by_month/
  # ManualRevenueEntry — a soma bate exatamente com @monthly_revenue.
  def monthly_summary_by_client(clinic, month)
    per_client = Hash.new { |h, k| h[k] = { name: nil, turnos_cents: 0, insumos_cents: 0, credits_cents: 0, turnos: [], insumos: [] } }

    revenue_entries(clinic).each do |e|
      next unless e[:month] == month
      dentist = e[:group].dentist
      entry   = per_client[dentist.id]
      entry[:name] ||= dentist.name
      entry[:turnos_cents]  += e[:turnos_cents]
      entry[:insumos_cents] += e[:insumos_cents]
    end

    monthly_turnos_by_client(clinic, month).each do |row|
      next if row[:manual]
      entry = per_client[row[:client_id]]
      entry[:name] ||= row[:name]
      entry[:turnos].concat(row[:turnos])
    end

    monthly_extras_purchases(clinic, month).each do |row|
      next if row[:manual]
      entry = per_client[row[:client_id]]
      entry[:name] ||= row[:name]
      entry[:insumos].concat(row[:items])
    end

    ManualRevenueEntry.for_month(month).where(clinic: clinic).includes(:client).each do |e|
      entry = per_client[e.client_id]
      entry[:name] ||= e.client.name
      if e.category == "turno"
        entry[:turnos_cents] += e.amount_cents
        entry[:turnos] << "Lançamento manual"
      else
        entry[:insumos_cents] += e.amount_cents
        entry[:insumos] << "Lançamento manual"
      end
    end

    available_real_credits(clinic).where(created_at: month.all_month)
      .group(:user_id).sum(:amount_cents).each do |user_id, cents|
        entry = per_client[user_id]
        entry[:name] ||= User.find_by(id: user_id)&.name
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
    months = (@revenue_by_month.keys + @manual_by_month.keys + @credits_by_month.keys + [ Date.current.beginning_of_month ])
    months.uniq.sort.reverse
  end

  def build_monthly_series(clinic, months:)
    today = Date.current
    (0...months).map { |i| (today << i).beginning_of_month }.reverse.map do |start|
      t, i   = @revenue_by_month.fetch(start, [ 0, 0 ])
      mt, mi = @manual_by_month.fetch(start, [ 0, 0 ])
      cr     = @credits_by_month.fetch(start, 0)
      { month: start, turnos: t + mt, insumos: i + mi, credito: cr, total: t + mt + i + mi + cr }
    end
  end
end
