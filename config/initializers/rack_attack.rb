# Rate limiting e bloqueio de abuso (força bruta, scanners automatizados).
# Usa o Redis já existente como store. Só ativa se a gem estiver disponível.
if defined?(Rack::Attack)
  # Não aplica rate limiting durante os testes automatizados.
  Rack::Attack.enabled = false if Rails.env.test?

  class Rack::Attack
    # Cache store: reaproveita o Redis do app (mesmo do Sidekiq/ActionCable).
    redis_url = ENV["REDIS_URL"].presence
    if redis_url
      Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: redis_url)
    end

    ### Allowlist — nunca bloqueia o health check do Railway.
    safelist("allow health check") do |req|
      req.path == "/up"
    end

    ### Throttle geral por IP: no máx. 300 requisições / 5 min.
    throttle("req/ip", limit: 300, period: 5.minutes) do |req|
      req.ip unless req.path.start_with?("/assets", "/packs")
    end

    ### Login (POST /entrar): 10 tentativas / 20s por IP.
    throttle("logins/ip", limit: 10, period: 20.seconds) do |req|
      req.ip if req.post? && req.path == "/entrar"
    end

    ### Login por e-mail: 10 tentativas / 60s por conta (evita força bruta de senha).
    throttle("logins/email", limit: 10, period: 60.seconds) do |req|
      if req.post? && req.path == "/entrar"
        email = req.params.dig("user", "email").to_s.downcase.strip
        email.presence
      end
    end

    ### Cadastro (POST /): 5 contas / 5 min por IP (trava o scanner de contas).
    throttle("signups/ip", limit: 5, period: 5.minutes) do |req|
      req.ip if req.post? && req.path == "/"
    end

    ### Recuperação de senha (POST /password): 5 pedidos / 5 min por IP.
    throttle("password-reset/ip", limit: 5, period: 5.minutes) do |req|
      req.ip if req.post? && req.path == "/password"
    end

    ### Resposta padrão ao exceder o limite: 429 com Retry-After.
    self.throttled_responder = lambda do |req|
      match = req.env["rack.attack.match_data"] || {}
      retry_after = (match[:period] || 60).to_i
      [
        429,
        { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
        ["Muitas requisições. Tente novamente em instantes.\n"]
      ]
    end
  end
end
