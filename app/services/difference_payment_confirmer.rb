class DifferencePaymentConfirmer < ApplicationService
  def initialize(payment:)
    @payment = payment
  end

  def call
    return success(:not_found)         unless @payment
    return success(:already_processed) if @payment.paid?

    @payment.update!(status: "paid", paid_at: Time.current)
    success(@payment)
  rescue ActiveRecord::RecordInvalid => e
    log_error("payment=#{@payment&.id} error=#{e.message}")
    failure(e.message)
  end

  # Confirma a partir do payload do webhook/retorno (order_nsu = payment.id).
  def self.call_from_webhook(payload)
    payment = Payment.find_by(id: payload["order_nsu"])
    return unless payment

    result = call(payment: payment)

    if result.success? && payload["transaction_nsu"].present?
      payment.update_columns(gateway_id: payload["transaction_nsu"])
    end

    result
  end
end
