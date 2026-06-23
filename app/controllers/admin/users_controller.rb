class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :add_credit, :remove_credit]

  def index
    scope = policy_scope(User).where.not(role: "owner").order(:name)
    if params[:q].present?
      term  = "%#{params[:q].strip}%"
      scope = scope.where("name ILIKE :q OR email ILIKE :q", q: term)
    end
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
    # Histórico mostra só transações reais (confirmadas/canceladas) — sem expiradas/pendentes
    @booking_groups = @user.booking_groups
      .where(status: ["confirmed", "cancelled"])
      .includes(:payments, bookings: :availability)
      .order(created_at: :desc)
      .limit(10)
    @group_credits = Credit.where(source_booking_group_id: @booking_groups.map(&:id))
      .group(:source_booking_group_id).sum(:amount_cents)
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
      return redirect_to admin_users_path, alert: "Não é possível excluir seu próprio usuário."
    end

    if client_has_paid_history?(@user)
      return redirect_to admin_users_path,
        alert: "Não é possível excluir um cliente com reservas pagas."
    end

    ActiveRecord::Base.transaction do
      # Remove dados sem pagamento confirmado: compras de crédito, créditos (demo/usados)
      # e reservas abandonadas (pendentes/expiradas/canceladas).
      CreditPurchase.where(user: @user).delete_all
      Credit.where(user: @user).delete_all
      @user.booking_groups.destroy_all
      @user.destroy!
    end
    redirect_to admin_users_path, notice: "Cliente removido."
  rescue ActiveRecord::InvalidForeignKey,
         ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError
    redirect_to admin_users_path,
      alert: "Não foi possível excluir este cliente."
  end

  def add_credit
    amount_cents = (params[:amount].to_f * 100).to_i
    if amount_cents <= 0
      return redirect_to admin_user_path(@user), alert: "Valor inválido."
    end
    Credit.create!(user: @user, clinic: current_user.clinic, amount_cents: amount_cents,
                   in_revenue: params[:in_revenue] == "1",
                   reason: "Crédito adicionado pelo admin")
    redirect_to admin_user_path(@user), notice: "Crédito adicionado com sucesso."
  end

  def remove_credit
    amount_cents = (params[:amount].to_f * 100).to_i
    # Marcado: tira dos créditos que entram na receita (sai da receita do mês);
    # desmarcado: tira dos que estão fora da receita.
    from_revenue = params[:from_revenue] == "1"

    pool = Credit.available.where(user: @user, clinic: current_user.clinic, in_revenue: from_revenue)
    available = pool.sum(:amount_cents)
    if amount_cents <= 0 || amount_cents > available
      return redirect_to admin_user_path(@user),
        alert: "Valor inválido ou excede o saldo desse tipo de crédito (R$ #{format('%.2f', available / 100.0)})."
    end

    remaining = amount_cents
    pool.order(:created_at).each do |c|
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

  # Só um PAGAMENTO confirmado (dinheiro recebido) impede a exclusão.
  # Créditos (demo/usados) e reservas pendentes/expiradas/canceladas NÃO contam.
  def client_has_paid_history?(user)
    Payment.joins(:booking_group)
           .where(booking_groups: { dentist_id: user.id }, status: "paid").exists?
  end

  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  def admin_user_params
    p = params.require(:user).permit(:name, :phone, :birth_date, :cpf, :cro, :specialty, :role, :discount_per_slot)
    if p.key?(:discount_per_slot)
      p[:discount_per_slot_cents] = price_to_cents(p.delete(:discount_per_slot)).to_i
    end
    p
  end

  def admin_user_create_params
    params.require(:user).permit(:name, :email, :phone, :birth_date, :cpf, :cro, :specialty)
  end
end
