class PaymentConfirmer < ApplicationService
  def initialize(external_reference:)
    @external_reference = external_reference
  end

  def call
    group = BookingGroup.find_by(id: @external_reference)
    return success(:not_found) if group.nil?
    return success(:already_processed) if group.confirmed? || group.expired?

    ActiveRecord::Base.transaction do
      payment = group.payment

      group.update!(status: "confirmed")
      group.bookings.update_all(status: "confirmed")
      payment.update!(status: "paid", paid_at: Time.current)
    end

    broadcast_confirmed(group.payment.reload)
    success(group)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[PaymentConfirmer] ref=#{@external_reference} error=#{e.message}")
    failure(e.message)
  end

  private

  def broadcast_confirmed(payment)
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_#{payment.id}",
      target:  "payment_status",
      partial: "payments/paid",
      locals:  { payment: payment }
    )
  rescue => e
    Rails.logger.error("[PaymentConfirmer] broadcast failed: #{e.message}")
  end
end
