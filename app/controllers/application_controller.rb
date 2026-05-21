class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_paper_trail_whodunnit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_locale
    I18n.locale = :"pt-BR"
  end

  def user_not_authorized
    flash[:alert] = t("errors.not_authorized", default: "Você não tem permissão para esta ação.")
    redirect_back(fallback_location: root_path)
  end

  def user_for_paper_trail
    current_user&.id || "sistema"
  end

  def after_sign_in_path_for(resource)
    resource.owner? ? admin_root_path : root_path
  end
end
