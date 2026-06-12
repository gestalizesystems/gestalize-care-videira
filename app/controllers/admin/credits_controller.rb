class Admin::CreditsController < Admin::BaseController
  before_action :set_user, only: [:create, :destroy]

  def index
    scope = Credit
      .where(clinic: current_user.clinic)
      .includes(:user, :source_booking_group, :used_on_booking_group)
      .order(created_at: :desc)

    scope = scope.available if params[:status] == "available"
    scope = scope.used      if params[:status] == "used"

    @pagy, @credits = pagy(scope)
  end

  def create
    amount_cents = (params[:amount].to_f * 100).to_i

    if amount_cents <= 0
      return redirect_to admin_user_path(@user), alert: "Valor inválido."
    end

    Credit.create!(
      user:         @user,
      clinic:       current_user.clinic,
      amount_cents: amount_cents,
      reason:       "Crédito adicionado pelo admin"
    )

    redirect_to admin_user_path(@user), notice: "Crédito adicionado com sucesso."
  end

  def destroy
    amount_cents = (params[:amount].to_f * 100).to_i
    available = Credit.balance_for(user: @user, clinic: current_user.clinic)

    if amount_cents <= 0 || amount_cents > available
      return redirect_to admin_user_path(@user),
        alert: "Valor inválido ou excede o saldo disponível."
    end

    remaining = amount_cents
    Credit.available.where(user: @user, clinic: current_user.clinic)
          .order(:created_at).each do |credit|
      break if remaining <= 0
      if credit.amount_cents <= remaining
        remaining -= credit.amount_cents
        credit.update!(used_at: Time.current)
      else
        credit.update!(amount_cents: credit.amount_cents - remaining)
        remaining = 0
      end
    end

    redirect_to admin_user_path(@user), notice: "Crédito excluído com sucesso."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
