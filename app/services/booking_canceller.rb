class BookingCanceller < ApplicationService
  def initialize(booking:, reason: nil)
    @booking = booking
    @reason  = reason
  end

  def call
    return failure("Reserva já cancelada.") if @booking.cancelled?

    unless @booking.availability.cancellable?
      lead = ENV.fetch("CANCELLATION_LEAD_HOURS", 48).to_i
      return failure("Cancelamento deve ser feito com #{lead}h de antecedência.")
    end

    ActiveRecord::Base.transaction do
      @booking.update!(status: "cancelled")
      @booking.availability.update!(status: "available")

      group = @booking.booking_group
      if group.bookings.where.not(status: "cancelled").none?
        group.update!(status: "cancelled")
      end
    end

    success(@booking)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end
end
