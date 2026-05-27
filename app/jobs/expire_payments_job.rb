class ExpirePaymentsJob < ApplicationJob
  queue_as :critical

  def perform
    Payment.expired_unpaid.includes(:booking_group).find_each do |payment|
      next if payment.booking_group.expired?

      ActiveRecord::Base.transaction do
        payment.update!(status: "expired")
        payment.booking_group.expire!
      end

      broadcast_expired(payment.reload)
    rescue => e
      Rails.logger.error("[ExpirePaymentsJob] payment=#{payment.id} error=#{e.message}")
    end
  end

  private

  def broadcast_expired(payment)
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_#{payment.id}",
      target:  "payment_status",
      partial: "payments/payments/expired",
      locals:  { payment: payment }
    )
  rescue => e
    Rails.logger.error("[ExpirePaymentsJob] broadcast failed payment=#{payment.id} #{e.message}")
  end
end
