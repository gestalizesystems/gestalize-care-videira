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

    @monthly_turnos, @monthly_insumos = @revenue_by_month.fetch(@month, [0, 0])
    @monthly_credits = @credits_by_month.fetch(@month, 0)
    @monthly_revenue = @monthly_turnos + @monthly_insumos + @monthly_credits

    @available_months = months_with_history(clinic)
    @monthly_series   = build_monthly_series(clinic, months: 6)
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

  # { mês(Date) => [turnos_cents, insumos_cents] }
  # Cada fonte de pagamento de uma reserva confirmada (Pix/admin OU crédito) é
  # atribuída ao mês em que entrou: pagamento externo pelo paid_at; crédito pela
  # data de COMPRA (created_at). Assim crédito comprado em maio e usado em junho
  # conta em maio.
  def revenue_by_month(clinic)
    groups = confirmed_groups(clinic)
    off    = Credit.where(used_on_booking_group: groups.map(&:id), in_revenue: false)
                   .group(:used_on_booking_group_id).sum(:amount_cents)
    used_credits = real_credits(clinic).where.not(used_on_booking_group_id: nil)
                                       .group_by(&:used_on_booking_group_id)

    acc = Hash.new { |h, k| h[k] = [0, 0] }
    groups.each do |g|
      insumos   = extras_cents(g.extras)
      countable = [g.total_cents.to_i - off[g.id].to_i, 0].max
      next if countable <= 0
      turnos_part = countable - [insumos, countable].min

      sources = []
      g.payments.each do |p|
        sources << [p.paid_at, p.amount_cents.to_i] if p.paid? && %w[infinitepay admin].include?(p.gateway)
      end
      (used_credits[g.id] || []).each { |cr| sources << [cr.created_at, cr.amount_cents.to_i] }
      sources.sort_by! { |date, _| date || Time.at(0) }

      remaining = countable
      sources.each do |date, amount|
        take = [amount, remaining].min
        break if take <= 0
        remaining -= take
        month = (date || g.created_at).to_date.beginning_of_month
        t = (take * turnos_part / countable.to_f).round
        acc[month][0] += t
        acc[month][1] += take - t
      end
    end
    acc
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
    months = (@revenue_by_month.keys + @credits_by_month.keys + [Date.current.beginning_of_month])
    months.uniq.sort.reverse
  end

  def build_monthly_series(clinic, months:)
    today = Date.current
    (0...months).map { |i| (today << i).beginning_of_month }.reverse.map do |start|
      t, i = @revenue_by_month.fetch(start, [0, 0])
      cr   = @credits_by_month.fetch(start, 0)
      { month: start, turnos: t, insumos: i, credito: cr, total: t + i + cr }
    end
  end
end
