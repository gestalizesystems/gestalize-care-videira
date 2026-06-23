class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_paper_trail_whodunnit
  before_action :require_complete_profile

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_locale
    I18n.locale = :"pt-BR"
  end

  # Força quem tem cadastro incompleto (ex.: entrou pelo Google) a preencher
  # CPF, CRO, telefone e aceitar os termos antes de usar o sistema.
  def require_complete_profile
    return unless user_signed_in?
    return if current_user.profile_complete?
    return if devise_controller?
    return if controller_path == "users/profile_completions"
    return if request.path == terms_path
    redirect_to profile_completion_path
  end

  def user_not_authorized
    flash[:alert] = t("errors.not_authorized", default: "Você não tem permissão para esta ação.")
    redirect_back(fallback_location: root_path)
  end

  def user_for_paper_trail
    current_user&.id || "sistema"
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || (resource.owner? ? admin_root_path : root_path)
  end
end
