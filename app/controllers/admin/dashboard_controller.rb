class Admin::DashboardController < Admin::BaseController
  def index
    clinic = current_user.clinic

    # Mês selecionado (padrão: mês atual).
    @month = parse_month(params[:month]) || Date.current.beginning_of_month
    range  = @month..@month.end_of_month

    # Créditos TOTAIS: saldo de crédito (dinheiro real) ainda não usado em todas
    # as carteiras. Snapshot — NÃO muda ao trocar o mês; sobe ao comprar crédito
    # e baixa quando o cliente usa numa reserva.
    @total_credits = available_real_credits(clinic).sum(:amount_cents)

    # Por mês:
    @monthly_turnos, @monthly_insumos = revenue_split(clinic, range)
    # Crédito comprado no mês e ainda não usado (vira receita quando usado).
    @monthly_credits = credits_in_month(clinic, @month)
    @monthly_revenue = @monthly_turnos + @monthly_insumos + @monthly_credits

    # Meses com histórico (para o select) e série do gráfico (últimos 6 meses).
    @available_months = months_with_history(clinic)
    @monthly_series   = build_monthly_series(clinic, months: 6)
  end

  private

  # Créditos disponíveis (não usados) que representam dinheiro real: exclui
  # promocional e os marcados para não entrar na receita (in_revenue: false).
  def available_real_credits(clinic)
    Credit.available.where(clinic: clinic, in_revenue: true)
      .where.not("reason ILIKE ?", "%promocional%")
  end

  # Crédito real comprado/criado no mês e ainda disponível (não usado).
  def credits_in_month(clinic, month)
    available_real_credits(clinic)
      .where(created_at: month.beginning_of_month.beginning_of_day..month.end_of_month.end_of_day)
      .sum(:amount_cents)
  end

  def revenue_split(clinic, range)
    groups = confirmed_groups(clinic).select { |g| range.cover?(group_paid_at(g).to_date) }
    off_books = Credit.where(used_on_booking_group: groups.map(&:id), in_revenue: false)
                      .group(:used_on_booking_group_id).sum(:amount_cents)

    turnos = insumos = 0
    groups.each do |g|
      ins       = extras_cents(g.extras)
      countable = [g.total_cents.to_i - off_books[g.id].to_i, 0].max
      g_insumos = [ins, countable].min
      insumos  += g_insumos
      turnos   += countable - g_insumos
    end
    [turnos, insumos]
  end

  def confirmed_groups(clinic)
    @confirmed_groups ||= BookingGroup.where(clinic: clinic, status: "confirmed").includes(:payments).to_a
  end

  def group_paid_at(group)
    group.payments.select(&:paid?).filter_map(&:paid_at).min || group.created_at
  end

  def extras_cents(extras)
    Array(extras).sum { |e| e["price_cents"].to_i * e["quantity"].to_i }
  end

  def parse_month(value)
    return nil if value.blank?
    Date.strptime(value, "%Y-%m").beginning_of_month
  rescue ArgumentError
    nil
  end

  # Meses (início do mês) que têm reserva confirmada ou crédito — do mais recente
  # ao mais antigo. Inclui sempre o mês atual.
  def months_with_history(clinic)
    g = confirmed_groups(clinic).map { |bg| group_paid_at(bg).to_date.beginning_of_month }
    c = available_real_credits(clinic).pluck(:created_at).map { |d| d.to_date.beginning_of_month }
    (g + c + [Date.current.beginning_of_month]).uniq.sort.reverse
  end

  # Série dos últimos N meses para o gráfico empilhado (turnos/insumos/crédito).
  def build_monthly_series(clinic, months:)
    today = Date.current
    (0...months).map { |i| (today << i).beginning_of_month }.reverse.map do |start|
      range = start..start.end_of_month
      t, i  = revenue_split(clinic, range)
      cr    = credits_in_month(clinic, start)
      { month: start, turnos: t, insumos: i, credito: cr, total: t + i + cr }
    end
  end
end
