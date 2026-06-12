class Admin::PaymentsController < Admin::BaseController
  def index
    scope = policy_scope(Payment)
      .includes(booking_group: :dentist)
      .order(created_at: :desc)

    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @payments = pagy(scope)
  end

  def show
    @payment = policy_scope(Payment)
      .includes(booking_group: [:dentist, :bookings])
      .find(params[:id])
    @versions = @payment.versions.order(created_at: :desc)
  end
end
