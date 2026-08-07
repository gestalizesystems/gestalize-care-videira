class BookingCanceller < ApplicationService
  def initialize(booking:, reason: nil)
    @booking = booking
    @reason  = reason
  end

  def call
    return failure("Reserva já cancelada.") if @booking.cancelled?

    if @booking.booking_group.bookings.count > 1
      return failure("Turnos reservados em grupo só podem ser alterados, não cancelados.")
    end

    unless @booking.availability.cancellable?
      lead = ENV.fetch("CANCELLATION_LEAD_HOURS", 24).to_i
      return failure("Cancelamento deve ser feito com #{lead}h de antecedência.")
    end

    group               = @booking.booking_group
    group_was_confirmed = group.confirmed?

    ActiveRecord::Base.transaction do
      @booking.update!(status: "cancelled")
      @booking.availability.update!(status: "available")

      remaining = group.bookings.where.not(status: "cancelled")
      if remaining.none?
        group.update!(status: "cancelled")
      else
        new_subtotal = remaining.sum(:price_cents) + group.extras_total_cents
        new_total    = [ new_subtotal - group.discount_cents.to_i, 0 ].max
        group.update!(subtotal_cents: new_subtotal, total_cents: new_total)
      end
    end

    GoogleCalendarSyncJob.perform_later("remove", @booking.id)
    BookingMailer.admin_cancellation_notification(@booking, group).deliver_later
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
