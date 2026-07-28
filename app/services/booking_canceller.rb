class BookingCanceller < ApplicationService
  def initialize(booking:, reason: nil)
    @booking = booking
    @reason  = reason
  end

  def call
    return failure("Reserva já cancelada.") if @booking.cancelled?

    unless @booking.availability.cancellable?
      lead = ENV.fetch("CANCELLATION_LEAD_HOURS", 24).to_i
      return failure("Cancelamento deve ser feito com #{lead}h de antecedência.")
    end

    group               = @booking.booking_group
    group_was_confirmed = group.confirmed?
    booking_price       = @booking.price_cents

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
    issue_credit_if_eligible(group, group_was_confirmed, booking_price)

    success(@booking)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def issue_credit_if_eligible(group, group_was_confirmed, booking_price)
    return unless group_was_confirmed

    if group.reload.cancelled?
      BookingMailer.cancellation(group).deliver_later
      result = CreditIssuer.call(booking_group: group, reason: @reason)
      BookingMailer.credit_issued(group.dentist, result.value).deliver_later if result.success? && result.value
    else
      # Cancelamento parcial: crédito proporcional ao turno cancelado
      Credit.create!(
        user:                 group.dentist,
        clinic:               group.clinic,
        source_booking_group: group,
        amount_cents:         booking_price,
        reason:               @reason || "Cancelamento parcial de reserva"
      )
    end
  end
end
