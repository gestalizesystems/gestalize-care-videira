class Admin::BaseController < ApplicationController
  before_action :require_owner!

  layout "admin"

  private

  def require_owner!
    redirect_to root_path, alert: "Acesso restrito ao proprietário." unless current_user&.owner?
  end

  def current_clinic
    @current_clinic ||= current_user.clinic
  end

  def price_to_cents(value)
    return nil if value.blank?
    (value.to_s.gsub(",", ".").to_f * 100).round
  end
end
