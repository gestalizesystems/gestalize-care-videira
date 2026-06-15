class Auth::RegistrationsController < Devise::RegistrationsController
  skip_before_action :authenticate_user!, only: [:new, :create]

  protected

  def build_resource(hash = {})
    super
    resource.clinic ||= Clinic.first
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation,
      :phone, :birth_date, :cpf, :cro, :specialty, :terms_accepted)
  end

  def account_update_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation,
      :current_password, :phone, :birth_date, :cpf, :avatar)
  end
end
