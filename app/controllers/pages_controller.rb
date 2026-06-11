class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    min_date = Date.tomorrow
    requested = params[:date].present? ? Date.parse(params[:date]) : min_date
    @date = [requested, min_date].max
    @date = [@date, Date.current + 3.months].min

    @availabilities = Availability
      .available
      .where(date: @date, clinic: Current.clinic)
      .includes(:service, :dentist)
      .order(:starts_at)
  rescue Date::Error
    @date = min_date
    retry
  end

  def about; end
  def contact; end
end
