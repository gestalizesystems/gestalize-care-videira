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

    group               = @booking.booking_group
    group_was_confirmed = group.confirmed?

    ActiveRecord::Base.transaction do
      @booking.update!(status: "cancelled")
      @booking.availability.update!(status: "available")

      if group.bookings.where.not(status: "cancelled").none?
        group.update!(status: "cancelled")
      end
    end

    issue_credit_if_eligible(group, group_was_confirmed)

    success(@booking)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def issue_credit_if_eligible(group, group_was_confirmed)
    return unless group_was_confirmed && group.reload.cancelled?

    BookingMailer.cancellation(group).deliver_later
    result = CreditIssuer.call(booking_group: group, reason: @reason)
    BookingMailer.credit_issued(group.dentist, result.value).deliver_later if result.success? && result.value
  end
end
