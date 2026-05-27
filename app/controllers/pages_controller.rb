class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    min_date = Date.tomorrow
    requested = params[:date].present? ? Date.parse(params[:date]) : min_date
    @date = [requested, min_date].max
    @date = [@date, min_date + 90.days].min

    @availabilities = Availability
      .available
      .where(date: @date, clinic: Clinic.first)
      .includes(:service, :dentist)
      .order(:starts_at)
  rescue Date::Error
    @date = min_date
    retry
  end

  def about; end
  def contact; end
end
