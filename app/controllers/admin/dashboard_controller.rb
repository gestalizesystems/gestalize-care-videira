class Admin::DashboardController < Admin::BaseController
  def index
    @pending_payments  = Payment.pending.count
    @todays_bookings   = Booking.joins(:availability)
      .where(availabilities: { date: Date.current }).count
    @monthly_revenue   = Payment.paid
      .where(paid_at: Date.current.beginning_of_month..)
      .sum(:amount_cents) / 100.0
  end
end
