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

    # Receita que entrou na conta no mês (pagamentos confirmados) — em centavos
    @monthly_revenue = Payment.paid.where(clinic: clinic)
      .where(paid_at: Date.current.beginning_of_month..Date.current.end_of_month)
      .sum(:amount_cents)

    @monthly_series = build_monthly_series(clinic, months: 6)
  end

  private

  def build_monthly_series(clinic, months:)
    today = Date.current
    (0...months).map { |i| (today << i).beginning_of_month }.reverse.map do |start|
      cents = Payment.paid.where(clinic: clinic, paid_at: start..start.end_of_month).sum(:amount_cents)
      { month: start, cents: cents }
    end
  end
end
