class Admin::DashboardController < Admin::BaseController
  def index
    clinic = current_user.clinic

    # Reservas confirmadas para hoje
    @todays_bookings = Booking.where(clinic: clinic, status: "confirmed")
      .joins(:availability)
      .where(availabilities: { date: Date.current }).count

    # Turnos no carrinho ainda não pagos (grupos com pagamento pendente)
    @pending_payments = Booking.where(clinic: clinic)
      .joins(booking_group: :payment)
      .where(payments: { status: "pending" }).count

    # Receita = valor das reservas CONFIRMADAS, contado uma vez por reserva
    # (turnos = total − insumos). Exclui reservas pagas INTEIRAMENTE com crédito
    # do cliente (essas não são dinheiro novo) e canceladas/expiradas. Reservas
    # com qualquer pagamento externo (Pix/admin) contam pelo valor total.
    range = Date.current.beginning_of_month..Date.current.end_of_month
    @monthly_turnos, @monthly_insumos = revenue_split(clinic, range)
    @monthly_revenue = @monthly_turnos + @monthly_insumos

    @monthly_series = build_monthly_series(clinic, months: 6)
  end

  private

  def revenue_split(clinic, range)
    turnos = insumos = 0
    countable_groups(clinic).each do |g|
      next unless range.cover?(group_paid_at(g))
      ins = extras_cents(g.extras)
      turnos  += [g.total_cents.to_i - ins, 0].max
      insumos += ins
    end
    [turnos, insumos]
  end

  # Reservas confirmadas com ao menos um pagamento externo (não pagas só com
  # crédito do cliente).
  def countable_groups(clinic)
    BookingGroup.where(clinic: clinic, status: "confirmed").includes(:payments).select do |g|
      g.payments.any? { |p| p.paid? && p.gateway != "credit" }
    end
  end

  # Mês da receita: data do 1º pagamento confirmado (fallback: criação).
  def group_paid_at(group)
    group.payments.select(&:paid?).filter_map(&:paid_at).min || group.created_at
  end

  def extras_cents(extras)
    Array(extras).sum { |e| e["price_cents"].to_i * e["quantity"].to_i }
  end

  def build_monthly_series(clinic, months:)
    groups = countable_groups(clinic)
    today  = Date.current
    (0...months).map { |i| (today << i).beginning_of_month }.reverse.map do |start|
      range = start..start.end_of_month
      cents = groups.sum { |g| range.cover?(group_paid_at(g)) ? g.total_cents.to_i : 0 }
      { month: start, cents: cents }
    end
  end
end
