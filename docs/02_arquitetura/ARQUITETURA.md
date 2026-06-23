# Videira Dental Clinic — ARQUITETURA.md

> Arquitetura **real e atual** do sistema VDC, conferida contra o código.
> Última atualização: 2026-06-10 (auditoria código × docs)

---

## 1. Visão geral

VDC é uma aplicação **Rails 7.2 fullstack monolítica** com Hotwire (Turbo + Stimulus). Não há SPA, não há API JSON pública. O navegador recebe HTML renderizado pelo Rails; a interatividade é incremental (Turbo Frames/Streams + Stimulus).

Princípios em vigor no código:

1. **Convention over configuration.** Onde Rails define um padrão, segui-lo.
2. **Models magros / services finos / controllers RESTful.** Lógica de domínio no model; orquestração cross-model e I/O externo em services; controllers só convertem HTTP em chamadas de domínio.
3. **Tenant único por deploy, multi-clínica preparado.** `Current.clinic` (CurrentAttributes) resolve a clínica via `ENV["CLINIC_ID"]` com fallback `Clinic.first`.
4. **Auditoria por padrão.** Entidades com mutação relevante têm `has_paper_trail`.
5. **Dinheiro em centavos.** Todas as colunas monetárias são `*_cents` (integer). O concern `MoneyConvertible` (`money_field :price`) expõe o valor em reais como float para exibição.
6. **Enums como string + check constraint no Postgres.** `enum :status, { pending: "pending", ... }` — legível no banco e protegido por constraint (diferente do plano original de enums integer).
7. **Pessimistic locking + unique index** contra double-booking (`lock!` no checkout + index único parcial em `bookings.availability_id` para status ≠ cancelled).

---

## 2. Estrutura real de pastas (app/)

```
app/
├── controllers/
│   ├── application_controller.rb        ← Pundit + Pagy + Devise + PaperTrail whodunnit
│   ├── pages_controller.rb              ← home (slots públicos), sobre, contato
│   ├── auth/                            ← Devise customizado
│   │   ├── sessions_controller.rb
│   │   ├── registrations_controller.rb
│   │   └── omniauth_callbacks_controller.rb
│   ├── scheduling/
│   │   ├── carts_controller.rb          ← session[:cart_ids] add/remove/clear
│   │   └── bookings_controller.rb       ← confirmar (new/create), index, show, cancelar
│   ├── payments/
│   │   ├── payments_controller.rb       ← show, pending (redirect ao checkout), return, cancel
│   │   └── webhooks_controller.rb       ← POST /webhooks/infinitepay (reserva OU recarga)
│   ├── users/
│   │   ├── profiles_controller.rb       ← /perfil
│   │   ├── wallets_controller.rb        ← /carteira (saldo de créditos)
│   │   └── credit_purchases_controller.rb ← POST /recargas (recarga via Pix)
│   └── admin/                           ← herdam de Admin::BaseController (require_owner!)
│       ├── base_controller.rb
│       ├── dashboard_controller.rb      ← KPIs + gráfico de receita
│       ├── clinics_controller.rb
│       ├── users_controller.rb          ← + add_credit / remove_credit
│       ├── services_controller.rb
│       ├── availabilities_controller.rb ← + toggle (bloquear/liberar)
│       ├── discount_rules_controller.rb
│       ├── bookings_controller.rb       ← + create manual, cancelar, alterar-turno
│       ├── payments_controller.rb
│       └── credits_controller.rb
├── models/
│   ├── current.rb                       ← Current.clinic (CurrentAttributes)
│   ├── concerns/money_convertible.rb    ← money_field :price → price_cents/100.0
│   ├── clinic.rb  user.rb  service.rb   ← Service = tipo de turno/atendimento (não há Room)
│   ├── availability.rb                  ← status: available/booked/cancelled/blocked
│   ├── discount_rule.rb  booking_group.rb  booking.rb  payment.rb
│   ├── credit.rb                        ← crédito em conta (cancelamento ou recarga)
│   └── credit_purchase.rb               ← recarga de crédito via Pix (InfinitePay)
├── services/
│   ├── application_service.rb           ← Result struct (success?/value/error) + log helpers
│   ├── discount_calculator.rb
│   ├── booking_group_creator.rb         ← transação + FOR UPDATE + abate créditos
│   ├── booking_canceller.rb             ← regra 48h + libera slot + emite crédito
│   ├── credit_issuer.rb
│   ├── credit_purchase_confirmer.rb     ← confirma recarga e cria Credit
│   ├── payment_confirmer.rb             ← idempotente; broadcast Turbo + mailer
│   ├── admin_booking_creator.rb         ← reserva manual criada pela owner
│   ├── admin_booking_group_creator.rb
│   ├── admin_booking_slot_changer.rb    ← troca turno; cobra/credita diferença de preço
│   ├── difference_payment_confirmer.rb  ← confirma pagamento de diferença (order_nsu = payment.id)
│   └── infinite_pay/
│       ├── checkout_creator.rb          ← POST /links (reserva)
│       ├── credit_checkout_creator.rb   ← POST /links (recarga)
│       ├── difference_checkout_creator.rb ← POST /links (diferença na troca de turno)
│       └── payment_checker.rb           ← POST /payment_check (fallback do webhook)
├── jobs/
│   └── expire_payments_job.rb           ← sidekiq-cron a cada 5 min (fila :critical)
├── mailers/
│   └── booking_mailer.rb                ← confirmation, cancellation, credit_issued
├── policies/
│   ├── application_policy.rb
│   ├── booking_policy.rb  booking_group_policy.rb
│   ├── payment_policy.rb  user_policy.rb
│   └── (admin usa require_owner! no BaseController; nem todo recurso tem policy própria)
├── javascript/controllers/
│   ├── calendar_controller.js           ← calendário/seleção de data
│   ├── book_slot_controller.js          ← seleção de turnos
│   ├── countdown_controller.js  clipboard_controller.js
│   ├── flash_controller.js  input_mask_controller.js  password_toggle_controller.js
└── views/
    ├── layouts/ (application, admin, mailer)
    ├── pages/  scheduling/  payments/payments/  users/  auth/  admin/  shared/
    └── (catálogo completo de telas em docs/03_design/CATALOGO_TELAS.md)
```

> CSS: **Tailwind v4** via `tailwindcss-rails` (binário standalone). Não existe `tailwind.config.js` — tokens e classes utilitárias (`.btn-*`, `.card-*`, `.badge-*`) vivem em `app/assets/tailwind/application.css`. Ver `docs/03_design/DESIGN_SYSTEM.md`.

---

## 3. Camadas — regras em vigor

### 3.1 Models

- Dados, validações, associações, scopes e transições de estado (`confirm!`, `expire!`, `cancel!`).
- Sem callbacks com side-effects externos (jobs, mails, broadcasts) — esses ficam nos services.
- `has_paper_trail` nas entidades auditadas (User, Availability, BookingGroup, Booking, Payment, Credit, CreditPurchase, DiscountRule, Clinic).

### 3.2 Services

- Herdam de `ApplicationService`; o retorno é `Result` (`success?`, `value`, `error`) — não OpenStruct.
- Helpers privados: `success(value)`, `failure(error)`, `log_error`, `log_warn`.
- Nunca acessam `current_user` — recebem tudo como kwargs.
- Integrações em subnamespace: `InfinitePay::*`.
- Idempotência nos confirmadores (`PaymentConfirmer`, `CreditPurchaseConfirmer`): no-op se já processado.

### 3.3 Controllers

- RESTful; actions custom apenas quando necessário (`cancel`, `change_slot`, `toggle`, `return`).
- Admin herda de `Admin::BaseController` (`require_owner!` + layout admin + `price_to_cents`).
- Webhook (`Payments::WebhooksController`) herda direto de `ActionController::Base` com `protect_from_forgery with: :null_session` e responde sempre 200 para evitar retentativas em loop.
- Paths das rotas em **português** (`/carteira`, `/recargas`, `/reservas/confirmar`, `/pagamento/retorno`).

### 3.4 Jobs

- `ExpirePaymentsJob` (fila `:critical`): expira `Payment` pendente vencido + `BookingGroup` e faz broadcast. Agendado via sidekiq-cron (a cada 5 min).
- `ApplicationJob` tem `retry_on ActiveRecord::Deadlocked` e `discard_on ActiveJob::DeserializationError`.

### 3.5 Autorização

- Pundit no fluxo do dentista (`policy_scope` em pagamentos/reservas).
- No admin a defesa primária é o `require_owner!`; policies existem para os recursos compartilhados com o dentista.
- `rescue_from Pundit::NotAuthorizedError` → flash + `redirect_back`.

---

## 4. Fluxos críticos

### 4.1 Checkout de reserva (Pix via InfinitePay)

```
Dentista adiciona slots → session[:cart_ids]
        ↓
Scheduling::BookingsController#create
        ↓
BookingGroupCreator (transação):
  lock! availabilities (SELECT FOR UPDATE)
  re-valida disponibilidade
  cria BookingGroup + Bookings (pending) + marca slots booked
  abate créditos disponíveis (FIFO)
  se total restante > 0 → InfinitePay::CheckoutCreator (POST /links)
  cria Payment (gateway: infinitepay, checkout_url)
        ↓
Dentista é redirecionado ao checkout hospedado do InfinitePay
        ↓
InfinitePay → POST /webhooks/infinitepay (order_nsu = booking_group.id)
        ↓
PaymentConfirmer: confirma group + bookings + payment,
  broadcast Turbo Stream ("payment_<id>"), BookingMailer.confirmation
        ↓
Retorno (/pagamento/retorno): se webhook ainda não chegou,
  InfinitePay::PaymentChecker consulta o status como fallback
```

### 4.2 Recarga de crédito

```
Carteira (/carteira) → POST /recargas (valor livre)
        ↓
CreditPurchase (pending) → InfinitePay::CreditCheckoutCreator (order_nsu = purchase.id)
        ↓
Webhook ou retorno → CreditPurchaseConfirmer:
  cria Credit ("Recarga via Pix") + marca purchase paid
```

O webhook diferencia o tipo consultando onde o `order_nsu` existe: `booking_groups` (reserva → `PaymentConfirmer`), `credit_purchases` (recarga → `CreditPurchaseConfirmer`) ou `payments` (diferença de troca de turno → `DifferencePaymentConfirmer`).

### 4.2b Troca de turno com diferença de preço (admin)

`AdminBookingSlotChanger`: se o turno novo é **mais caro**, consome crédito disponível primeiro e, se restar valor, cria um `Payment` de diferença (`order_nsu = payment.id`, UUID gerado antes) com checkout InfinitePay próprio; se é **mais barato**, emite `Credit` com a diferença. Por isso `payments.booking_group_id` deixou de ser unique (1—N).

### 4.3 Cancelamento

```
Dentista cancela booking (≥ 48h de antecedência, CANCELLATION_LEAD_HOURS)
        ↓
BookingCanceller: cancela booking, libera availability,
  cancela o group se não restarem bookings ativos,
  CreditIssuer emite crédito se o grupo estava pago,
  BookingMailer.cancellation (+ credit_issued)
```

### 4.4 Expiração

`ExpirePaymentsJob` (5 em 5 min) expira payments pendentes vencidos e os grupos correspondentes, liberando os slots. **Atenção:** o job ainda **não** expira `CreditPurchase` pendente (pendência registrada no roadmap).

---

## 5. Concorrência e integridade

- **Double-booking:** `lock!` (FOR UPDATE) no checkout + index único parcial `idx_bookings_availability_unique_active` (`bookings.availability_id` where status ≠ cancelled) + index `idx_availabilities_no_double_booking` (`dentist_id, date, starts_at`).
- **Webhook duplicado:** confirmadores idempotentes (retornam `:already_processed`).
- **Race webhook × expiração:** `expire!` é no-op se o grupo já está confirmado; `PaymentConfirmer` é no-op se expirado.
- **Constraints no banco:** todos os status têm check constraint; valores monetários têm checks de positividade.

---

## 6. Segurança do webhook (estado atual)

O InfinitePay **não documenta assinatura HMAC**. A validação atual é:

1. `order_nsu` precisa existir como `BookingGroup` ou `CreditPurchase` (UUIDs não enumeráveis);
2. só processa `capture_method == "pix"` com `paid_amount > 0`.

Limitações conhecidas (itens do roadmap): não há comparação de `paid_amount` contra o valor esperado do pagamento, nem verificação ativa via `payment_check` antes de confirmar via webhook.

---

## 7. I18n e formatação

- Locale: `pt-BR` (forçado em `ApplicationController#set_locale`); `config/locales/pt-BR.yml`.
- Status na UI sempre via `t("modelo.status.#{obj.status}")` + helpers `*_status_badge`.
- Moeda via helper `money` (ver DESIGN_SYSTEM.md).

---

## 8. Testes

- **RSpec** — 148 exemplos: models, services, requests (admin + scheduling + webhooks) e system specs.
- System specs rodam com **Capybara + rack_test** (sem Selenium/Chrome — specs `js: true` não são suportados hoje).
- WebMock para o InfinitePay; FactoryBot + Faker; Shoulda-Matchers nos models.
- Qualidade: `bin/rubocop` (rubocop-rails-omakase) e `bin/brakeman`.
- CI: `.github/workflows/ci.yml` (brakeman, importmap audit, rubocop, rspec com Postgres + Redis como services).

---

## 9. Variáveis de ambiente (reais)

Fonte canônica: `.env.example`. Resumo:

```bash
DATABASE_URL=        # produção (dev usa peer auth)
REDIS_URL=redis://localhost:6379/0
SECRET_KEY_BASE=
GOOGLE_CLIENT_ID= / GOOGLE_CLIENT_SECRET=
INFINITEPAY_HANDLE=  # InfiniteTag sem "$"
APP_HOST=            # monta webhook_url e redirect_url
CANCELLATION_LEAD_HOURS=48
PAYMENT_EXPIRY_MINUTES=30
OWNER_PASSWORD=      # seed
MAILER_FROM= / SMTP_HOST= / SMTP_PORT= / SMTP_USERNAME= / SMTP_PASSWORD=
CLINIC_ID=           # opcional; resolve Current.clinic quando houver +1 clínica
```

> Não existem mais variáveis MercadoPago. O app não usa Rails credentials — é 100% ENV.

---

## 10. Deploy

Railway (Docker, serviço único: Puma + Sidekiq no mesmo container, com PostgreSQL e Redis como plugins gerenciados). Detalhes operacionais e troubleshooting no `README.md` e em `docs/05_setup/DEPLOY_PRODUCAO.md`.

---

*Documento alinhado ao código em 2026-06-10. Divergências históricas (MercadoPago, Room, enums integer, money decimal) estão registradas em `docs/01_projeto/ATIVIDADES_DECISOES.md`.*
