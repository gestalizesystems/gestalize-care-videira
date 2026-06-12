class CreditIssuer < ApplicationService
  def initialize(booking_group:, reason: nil)
    @group  = booking_group
    @reason = reason
  end

  def call
    return failure("Grupo de reserva inválido.") unless @group
    paid_total = @group.payments.paid.sum(:amount_cents)
    return success(nil) unless paid_total.positive?

    credit = Credit.create!(
      user:                 @group.dentist,
      clinic:               @group.clinic,
      source_booking_group: @group,
      amount_cents:         paid_total,
      reason:               @reason || "Cancelamento reserva ##{@group.id.split('-').first}"
    )

    success(credit)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end
end
