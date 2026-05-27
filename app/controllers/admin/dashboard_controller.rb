class Admin::DashboardController < Admin::BaseController
  def index
    clinic = current_user.clinic

    @pending_payments = Payment.pending.where(clinic: clinic).count
    @todays_bookings  = Booking.joins(:availability)
      .where(availabilities: { date: Date.current }, clinic: clinic).count
    @monthly_revenue  = Payment.paid.where(clinic: clinic)
      .where(paid_at: Date.current.beginning_of_month..)
      .sum(:amount_cents) / 100.0

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
