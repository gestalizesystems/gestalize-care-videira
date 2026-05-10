# Videira Dental Clinic

Sistema SaaS para aluguel de salas odontológicas. Dentistas buscam horários disponíveis, montam um carrinho com múltiplos slots e pagam via Pix em uma única transação. A clínica gerencia tudo pelo painel administrativo.

---

## Funcionalidades

- **Agendamento** — listagem de serviços e horários, carrinho por sessão, checkout com cálculo de desconto automático por volume
- **Pagamento Pix** — integração com MercadoPago, QR Code em tempo real, expiração automática via Sidekiq
- **Confirmação em tempo real** — webhook HMAC-SHA256 + Turbo Streams atualiza a tela do dentista sem refresh
- **Painel Admin** — gestão de clínica, dentistas, serviços, horários, regras de desconto, reservas e pagamentos
- **Autenticação** — Devise + login social Google OAuth 2.0
- **Auditoria** — histórico completo de alterações com PaperTrail

---

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Ruby on Rails 7.2 |
| Banco de dados | PostgreSQL (UUIDs via pgcrypto) |
| Frontend | Hotwire (Turbo + Stimulus) + Tailwind CSS |
| Background jobs | Sidekiq + Redis + sidekiq-cron |
| Pagamentos | MercadoPago SDK (Pix) |
| Auth | Devise + OmniAuth Google OAuth 2.0 |
| Autorização | Pundit |
| Auditoria | PaperTrail |
| Testes | RSpec + FactoryBot + Shoulda-Matchers + WebMock |

---

## Rodando localmente

### Pré-requisitos

- Ruby 3.2.3
- PostgreSQL
- Redis
- Node.js (para compilação do Tailwind)

### 1. Instalar dependências

```bash
bundle install
```

### 2. Configurar variáveis de ambiente

Copie o arquivo de exemplo e preencha os valores:

```bash
cp .env.example .env
```

As variáveis obrigatórias para desenvolvimento são:

| Variável | Descrição |
|---|---|
| `REDIS_URL` | URL do Redis (padrão: `redis://localhost:6379/0`) |
| `SECRET_KEY_BASE` | Gerado automaticamente no `.env.example` |
| `GOOGLE_CLIENT_ID` | Credencial OAuth no [Google Cloud Console](https://console.cloud.google.com) |
| `GOOGLE_CLIENT_SECRET` | Credencial OAuth no Google Cloud Console |
| `MERCADOPAGO_ACCESS_TOKEN` | Token Sandbox no [MercadoPago](https://www.mercadopago.com.br/developers) |
| `MERCADOPAGO_WEBHOOK_SECRET` | Secret de validação de webhook |
| `OWNER_PASSWORD` | Senha do usuário owner criado pelo seed |

> Enquanto não tiver as credenciais reais, o login Google mostrará erro e o Pix usará dados mockados (o sandbox é detectado automaticamente pelo prefixo `TEST-` no token).

### 3. Criar e migrar o banco de dados

O projeto usa autenticação peer do PostgreSQL — nenhuma senha é necessária em desenvolvimento, basta que seu usuário do sistema tenha permissão de superuser:

```bash
sudo -u postgres createuser $USER --superuser  # execute apenas uma vez
bin/rails db:create db:migrate db:seed
```

O seed cria a clínica e um usuário owner com o e-mail `owner@videiradental.com.br` e a senha definida em `OWNER_PASSWORD`.

### 4. Subir os serviços

```bash
bin/dev
```

Isso inicia em paralelo o servidor Rails, o compilador Tailwind e o Sidekiq (via `Procfile.dev`).

Ou, se preferir terminais separados:

```bash
bin/rails server     # Terminal 1
redis-server         # Terminal 2
bundle exec sidekiq  # Terminal 3
```

### 5. Acessar

| URL | Descrição |
|---|---|
| http://localhost:3000 | Aplicação principal |
| http://localhost:3000/admin | Painel administrativo (owner) |
| http://localhost:3000/admin/sidekiq | Monitor de jobs (owner) |

---

## Testes

```bash
bundle exec rspec
```

A suíte cobre modelos, serviços e requests (89 exemplos).

---

## Arquitetura resumida

```
app/
├── controllers/
│   ├── scheduling/        # Carrinho e reservas (paciente/dentista)
│   ├── payments/          # Pagamento Pix e webhook MercadoPago
│   └── admin/             # Painel administrativo
├── services/
│   ├── booking_group_creator.rb   # Cria reserva + pagamento em transação atômica
│   ├── booking_canceller.rb       # Valida regra de 48h e libera o slot
│   ├── payment_confirmer.rb       # Confirma pagamento e faz broadcast Turbo
│   └── mercado_pago/              # PixCreator, PaymentFinder, WebhookValidator
├── jobs/
│   └── expire_payments_job.rb     # Expira pagamentos pendentes a cada 5 min
└── models/
    ├── booking_group.rb   # Agrupa N bookings sob 1 pagamento
    ├── availability.rb    # Slot de horário do dentista
    └── payment.rb         # Registro de pagamento Pix
```

**Fluxo de pagamento:**

1. Dentista adiciona horários ao carrinho (`session[:cart_ids]`)
2. Checkout cria `BookingGroup` + `Booking`s + `Payment` em uma única transação com `FOR UPDATE` (evita double-booking)
3. MercadoPago retorna QR Code Pix exibido via Turbo Stream
4. Webhook valida assinatura HMAC-SHA256 e chama `PaymentConfirmer`
5. Turbo Stream atualiza a tela do dentista em tempo real

---

## Variáveis de ambiente completas

Veja o arquivo [`.env.example`](.env.example) para a lista completa com descrições.
