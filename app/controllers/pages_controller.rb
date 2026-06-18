class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
    min_date = Date.current
    requested = params[:date].present? ? Date.parse(params[:date]) : min_date
    @date = [requested, min_date].max
    @date = [@date, Date.current + 3.months].min

    @availabilities = Availability
      .available
      .where(date: @date, clinic: Current.clinic)
      .includes(:service, :dentist)
      .to_a
      .reject(&:past?)                              # esconde turnos cujo horário já passou
      .sort_by { |a| a.starts_at.strftime("%H:%M") } # ordena pelo horário local exibido
  rescue Date::Error
    @date = min_date
    retry
  end

  def about; end
  def contact; end
  def terms; end
end
