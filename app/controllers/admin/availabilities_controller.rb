class Admin::AvailabilitiesController < Admin::BaseController
  before_action :set_availability, only: [:edit, :update, :destroy, :toggle]

  def index
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @availabilities = current_clinic.availabilities
      .where(date: @date)
      .where(eclipsed_by_id: nil) # esconde turnos desativados por colisão de reserva
      .to_a
      # Diárias primeiro, depois os demais — cada grupo ordenado por horário local.
      .sort_by { |a| [a.diaria? ? 0 : 1, a.starts_at.strftime("%H:%M")] }
    @dentists = User.dentists.where(clinic: current_clinic).order(:name)
  rescue Date::Error
    redirect_to admin_availabilities_path, alert: "Data inválida."
  end

  def new
    @availability = Availability.new(date: params[:date], clinic: current_clinic)
  end

  def create
    @availability = current_clinic.availabilities.new(availability_params)

    if @availability.save
      redirect_to admin_availabilities_path(date: @availability.date),
        notice: "Turno criado com sucesso."
    else
      redirect_to admin_availabilities_path(date: availability_params[:date]),
        alert: @availability.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    if @availability.update(availability_params)
      redirect_to admin_availabilities_path(date: @availability.date), notice: "Turno atualizado."
    else
      redirect_to admin_availabilities_path(date: @availability.date),
                  alert: @availability.errors.full_messages.to_sentence
    end
  end

  def toggle
    if @availability.past?
      redirect_to admin_availabilities_path(date: @availability.date),
        alert: "Turno já passou — não pode ser ativado."
    elsif @availability.booked?
      redirect_to admin_availabilities_path(date: @availability.date),
        alert: "Turno reservado — não pode ser alterado."
    elsif @availability.available?
      @availability.update!(status: :blocked)
      redirect_to admin_availabilities_path(date: @availability.date)
    else
      @availability.update!(status: :available)
      redirect_to admin_availabilities_path(date: @availability.date)
    end
  end

  def destroy
    if @availability.booked?
      return redirect_to admin_availabilities_path(date: @availability.date),
        alert: "Turno reservado — não é possível excluir."
    end

    ActiveRecord::Base.transaction do
      # Remove vínculos mortos (reservas canceladas/expiradas) e libera quem este
      # turno tenha eclipsado, evitando violação de chave estrangeira.
      Booking.where(availability_id: @availability.id).delete_all
      current_clinic.availabilities.where(eclipsed_by_id: @availability.id)
        .update_all(status: "available", eclipsed_by_id: nil)
      @availability.destroy!
    end
    redirect_to admin_availabilities_path(date: @availability.date), notice: "Turno removido."
  rescue => e
    Rails.logger.error("[Availabilities#destroy] #{e.class}: #{e.message}")
    redirect_to admin_availabilities_path(date: @availability.date),
      alert: "Não foi possível excluir este turno."
  end

  private

  def set_availability
    @availability = current_clinic.availabilities.find(params[:id])
  end

  def availability_params
    p = params.require(:availability).permit(:date, :starts_at, :ends_at, :status, :price)
    p[:price_cents] = price_to_cents(p.delete(:price))
    p
  end
end
