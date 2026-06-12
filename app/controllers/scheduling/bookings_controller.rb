class Scheduling::BookingsController < ApplicationController
  before_action :authenticate_user!

  def index
    base = policy_scope(BookingGroup).includes(:bookings, :payment)

    @months = base.pluck(:created_at).map { |d| d.strftime("%Y-%m") }.uniq.sort.reverse
    @selected_month = params[:month].presence || @months.first

    scope = base.order(created_at: :desc)

    if @selected_month.present?
      year, month = @selected_month.split("-").map(&:to_i)
      scope = scope.where(created_at: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month)
    end

    @pagy, @booking_groups = pagy(scope)
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

    @pricing  = result.value
    @dentists = User.dentists.where(clinic: clinic).order(:name) if current_user.owner?
  end

  def create
    cart_ids = Array(session[:cart_ids])

    if cart_ids.empty?
      return redirect_to root_path, alert: "Selecione ao menos um horário antes de continuar."
    end

    if current_user.owner? && params[:dentist_id].present?
      clinic  = Availability.find_by(id: cart_ids.first)&.clinic
      dentist = User.dentists.where(clinic: clinic).find_by(id: params[:dentist_id])

      unless dentist
        return redirect_to confirmar_reservas_path, alert: "Dentista não encontrado."
      end

      result = AdminBookingGroupCreator.call(
        availability_ids: cart_ids,
        dentist:          dentist
      )

      if result.success?
        session.delete(:cart_ids)
        redirect_to admin_booking_path(result.value),
          notice: "Reserva criada para #{dentist.name}."
      else
        redirect_to confirmar_reservas_path, alert: result.error
      end
    else
      credit_cents = params[:credit_amount].present? ? (params[:credit_amount].to_s.tr(",", ".").to_f * 100).round : nil

      result = BookingGroupCreator.call(
        user:             current_user,
        availability_ids: cart_ids,
        credit_cents:     credit_cents
      )

      if result.success?
        session.delete(:cart_ids)
        redirect_to pagamento_path(result.value.payment),
          notice: "Reserva criada! Conclua o pagamento via Pix."
      else
        redirect_to confirmar_reservas_path, alert: result.error
      end
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
