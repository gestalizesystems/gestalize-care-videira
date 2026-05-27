class Admin::CreditsController < Admin::BaseController
  def index
    scope = Credit
      .where(clinic: current_user.clinic)
      .includes(:user, :source_booking_group, :used_on_booking_group)
      .order(created_at: :desc)

    scope = scope.available if params[:status] == "available"
    scope = scope.used      if params[:status] == "used"

    @pagy, @credits = pagy(scope)
  end
end
