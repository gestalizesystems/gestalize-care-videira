module InfinitePay
  # Consulta o status de um pagamento diretamente no InfinitePay.
  # Usado como fallback quando o webhook não chega antes do dentista retornar ao site.
  class PaymentChecker < ApplicationService
    BASE_URL = "https://api.checkout.infinitepay.io".freeze

    def initialize(order_nsu:, transaction_nsu:, slug:)
      @order_nsu       = order_nsu
      @transaction_nsu = transaction_nsu
      @slug            = slug
    end

    def call
      return failure("Parâmetros insuficientes.") if [@order_nsu, @transaction_nsu, @slug].any?(&:blank?)

      response = post_to_infinitepay
      body     = JSON.parse(response.body)

      if response.code.to_i == 200 && body["success"]
        success(body)
      else
        failure("Não foi possível verificar o pagamento.")
      end
    rescue => e
      Rails.logger.error("[InfinitePay::PaymentChecker] #{e.class}: #{e.message}")
      failure("Erro ao verificar pagamento.")
    end

    private

    def post_to_infinitepay
      require "net/http"
      uri  = URI("#{BASE_URL}/payment_check")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
      req.body = {
        handle:          ENV.fetch("INFINITEPAY_HANDLE"),
        order_nsu:       @order_nsu,
        transaction_nsu: @transaction_nsu,
        slug:            @slug
      }.to_json
      http.request(req)
    end
  end
end
