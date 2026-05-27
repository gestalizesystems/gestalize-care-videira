class Scheduling::BookingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @pagy, @booking_groups = pagy(
      policy_scope(BookingGroup).includes(:bookings, :payment).order(created_at: :desc)
    )
  end

  def show
    @booking_group = policy_scope(BookingGroup).find(params[:id])
    authorize @booking_group
  end

  def new
    cart_ids = Array(session[:cart_ids])

    if cart_ids.empty?
      return redirect_to root_path, alert: "Selecione ao menos um horário antes de continuar."
    end

    clinic = Availability.find_by(id: cart_ids.first)&.clinic

    result = DiscountCalculator.call(
      availability_ids: cart_ids,
      clinic:           clinic
    )

    if result.failure?
      return redirect_to root_path, alert: result.error
    end

    @pricing = result.value
  end

  def create
    cart_ids = Array(session[:cart_ids])

    if cart_ids.empty?
      return redirect_to root_path, alert: "Selecione ao menos um horário antes de continuar."
    end

    result = BookingGroupCreator.call(
      user:             current_user,
      availability_ids: cart_ids
    )

    if result.success?
      session.delete(:cart_ids)
      redirect_to pagamento_path(result.value.payment),
        notice: "Reserva criada! Conclua o pagamento via Pix."
    else
      redirect_to confirmar_reservas_path, alert: result.error
    end
  end

  def cancel
    booking = current_user.bookings.find(params[:id])
    authorize booking, :cancel?

    result = BookingCanceller.call(booking: booking)

    if result.success?
      redirect_to reservas_path, notice: "Reserva cancelada com sucesso."
    else
      redirect_to reserva_path(booking.booking_group), alert: result.error
    end
  end
end
