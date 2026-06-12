class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :add_credit, :remove_credit]

  def index
    scope = policy_scope(User).where.not(role: "owner").order(:name)
    scope = scope.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
    @pagy, @users = pagy(scope)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(admin_user_create_params)
    @user.clinic = current_user.clinic
    @user.role = "dentist"
    temp_password = SecureRandom.hex(8)
    @user.password = temp_password
    @user.password_confirmation = temp_password

    if @user.save
      redirect_to admin_user_path(@user), notice: "Cliente adicionado."
    else
      redirect_to admin_users_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def show
    @booking_groups = @user.booking_groups
      .includes(:bookings, :payment)
      .order(created_at: :desc)
      .limit(10)
    @versions = @user.versions.order(created_at: :desc).limit(20)
  end

  def edit; end

  def update
    if @user.update(admin_user_params)
      redirect_to admin_user_path(@user), notice: "Usuário atualizado."
    else
      redirect_to admin_user_path(@user), alert: @user.errors.full_messages.to_sentence
    end
  end

  def quick_create
    user = User.new(
      name:     params[:name],
      email:    params[:email],
      clinic:   current_clinic,
      role:     "dentist",
      password: SecureRandom.hex(16)
    )

    if user.save
      redirect_to admin_availabilities_path(date: params[:return_date]),
        notice: "Dentista \"#{user.name}\" cadastrado. Selecione-o na lista para confirmar a reserva."
    else
      redirect_to admin_availabilities_path(date: params[:return_date]),
        alert: user.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "Não é possível excluir seu próprio usuário."
    else
      @user.destroy!
      redirect_to admin_users_path, notice: "Usuário removido."
    end
  end

  def add_credit
    amount_cents = (params[:amount].to_f * 100).to_i
    if amount_cents <= 0
      return redirect_to admin_user_path(@user), alert: "Valor inválido."
    end
    Credit.create!(user: @user, clinic: current_user.clinic, amount_cents: amount_cents,
                   reason: "Crédito adicionado pelo admin")
    redirect_to admin_user_path(@user), notice: "Crédito adicionado com sucesso."
  end

  def remove_credit
    amount_cents = (params[:amount].to_f * 100).to_i
    available = Credit.balance_for(user: @user, clinic: current_user.clinic)
    if amount_cents <= 0 || amount_cents > available
      return redirect_to admin_user_path(@user), alert: "Valor inválido ou excede o saldo."
    end
    remaining = amount_cents
    Credit.available.where(user: @user, clinic: current_user.clinic).order(:created_at).each do |c|
      break if remaining <= 0
      if c.amount_cents <= remaining
        remaining -= c.amount_cents
        c.update!(used_at: Time.current)
      else
        c.update!(amount_cents: c.amount_cents - remaining)
        remaining = 0
      end
    end
    redirect_to admin_user_path(@user), notice: "Crédito excluído com sucesso."
  end

  private

  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  def admin_user_params
    params.require(:user).permit(:name, :phone, :birth_date, :cpf, :cro, :specialty, :role)
  end

  def admin_user_create_params
    params.require(:user).permit(:name, :email, :phone, :birth_date, :cpf, :cro, :specialty)
  end
end
