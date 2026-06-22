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
    range = Date.current.beginning_of_month..Date.current.end_of_month
    @monthly_revenue = Payment.paid.where(clinic: clinic, paid_at: range).sum(:amount_cents)

    # Separa a receita do mês em turnos vs insumos (Videira Shop).
    @monthly_turnos, @monthly_insumos = split_revenue(clinic, range)

    @monthly_series = build_monthly_series(clinic, months: 6)
  end

  private

  # Divide o valor recebido no período entre turnos e insumos, proporcional ao
  # peso dos insumos em cada pedido (garante turnos + insumos = receita total).
  def split_revenue(clinic, range)
    received = Hash.new(0)
    Payment.paid.where(clinic: clinic, paid_at: range)
      .where.not(booking_group_id: nil)
      .pluck(:booking_group_id, :amount_cents)
      .each { |gid, cents| received[gid] += cents }

    insumos = 0
    BookingGroup.where(id: received.keys).find_each do |g|
      got    = received[g.id]
      total  = g.total_cents.to_i
      extras = g.extras_total_cents
      share  = total.positive? ? (got * extras / total.to_f).round : 0
      insumos += [share, got].min
    end

    [@monthly_revenue - insumos, insumos]
  end

  def build_monthly_series(clinic, months:)
    today = Date.current
    (0...months).map { |i| (today << i).beginning_of_month }.reverse.map do |start|
      cents = Payment.paid.where(clinic: clinic, paid_at: start..start.end_of_month).sum(:amount_cents)
      { month: start, cents: cents }
    end
  end
end
