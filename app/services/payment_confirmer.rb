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
    BookingMailer.confirmation(group).deliver_later
    success(group)
  rescue ActiveRecord::RecordInvalid => e
    log_error("ref=#{@external_reference} error=#{e.message}")
    failure(e.message)
  end

  private

  def broadcast_confirmed(payment)
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_#{payment.id}",
      target:  "payment_status",
      partial: "payments/payments/paid",
      locals:  { payment: payment }
    )
  rescue => e
    log_error("broadcast failed: #{e.message}")
  end

  public

  # Confirma a partir do payload do webhook InfinitePay.
  # order_nsu = booking_group.id (passamos ao criar o checkout)
  def self.call_from_webhook(payload)
    order_nsu = payload["order_nsu"]
    return unless order_nsu.present? && payload["capture_method"] == "pix"

    result = call(external_reference: order_nsu)

    # Atualiza gateway_id com o transaction_nsu retornado pelo webhook
    if result.success? && payload["transaction_nsu"].present?
      group = BookingGroup.find_by(id: order_nsu)
      group&.payment&.update_columns(gateway_id: payload["transaction_nsu"])
    end

    result
  end
end
