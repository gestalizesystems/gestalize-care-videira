module MercadoPago
  class PixCreator < ApplicationService
    MOCK_TOKEN_PREFIX = "TEST-".freeze

    def initialize(booking_group, amount_cents: nil)
      @group        = booking_group
      @amount_cents = amount_cents || booking_group.total_cents
    end

    def call
      expires_at = ENV.fetch("PAYMENT_EXPIRY_MINUTES", 30).to_i.minutes.from_now

      return mock_result(expires_at) if sandbox?

      sdk  = Mercadopago::SDK.new(ENV.fetch("MERCADOPAGO_ACCESS_TOKEN"))
      resp = sdk.payment.create(
        transaction_amount: @amount_cents / 100.0,
        description:        "Aluguel de sala – Videira Dental",
        payment_method_id:  "pix",
        payer:              { email: @group.dentist.email },
        external_reference: @group.id,
        date_of_expiration: expires_at.iso8601,
        notification_url:   "#{ENV.fetch('APP_HOST', 'http://localhost:3000')}/webhooks/mercadopago"
      )

      if resp[:status] == 201
        data = resp[:response]
        txn  = data.dig("point_of_interaction", "transaction_data") || {}

        success({
          gateway_id:  data["id"].to_s,
          pix_qr_code: txn["qr_code"]         || sandbox_pix_code,
          pix_qr_url:  txn["qr_code_base64"]  || "",
          expires_at:  expires_at
        })
      else
        Rails.logger.error("[MercadoPago::PixCreator] status=#{resp[:status]} body=#{resp[:response].inspect}")
        failure("Serviço de pagamento indisponível. Tente novamente.")
      end
    rescue => e
      Rails.logger.error("[MercadoPago::PixCreator] #{e.class}: #{e.message}")
      failure("Erro ao conectar ao serviço de pagamento.")
    end

    private

    def sandbox?
      ENV.fetch("MERCADOPAGO_ACCESS_TOKEN", "").start_with?(MOCK_TOKEN_PREFIX) ||
        ENV.fetch("MERCADOPAGO_ACCESS_TOKEN", "").include?("000000000")
    end

    def mock_result(expires_at)
      success({
        gateway_id:  "SANDBOX_#{@group.id}",
        pix_qr_code: sandbox_pix_code,
        pix_qr_url:  "",
        expires_at:  expires_at
      })
    end

    def sandbox_pix_code
      "00020101021226930014BR.GOV.BCB.PIX0111#{@group.id.gsub('-', '')[0..10]}52040000530398654" \
        "#{format('%010.2f', @amount_cents / 100.0).delete('.')}5802BR5922VIDEIRA DENTAL SANDBOX" \
        "6009SAO PAULO62290525#{@group.id.gsub('-', '')[0..24]}6304ABCD"
    end
  end
end
