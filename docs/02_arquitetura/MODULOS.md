# Videira Dental Clinic — MODULOS.md

> Mapa funcional do sistema dividido em 6 módulos, conferido contra o código.
> Última atualização: 2026-06-10 (auditoria código × docs)

---

## Visão geral

| Módulo | Responsabilidade | Principal entrega ao usuário |
|---|---|---|
| **Auth** | Identidade, sessão, permissões | Dentista loga (email/senha ou Google); owner administra |
| **Scheduling** | Slots, carrinho, criação e cancelamento de reservas | Dentista escolhe e agenda; owner gerencia disponibilidade |
| **Payments** | Checkout InfinitePay, webhook, retorno, expiração | Dentista paga via Pix; sistema confirma a reserva |
| **Créditos / Carteira** | Saldo, emissão por cancelamento, recarga via Pix | Dentista acumula e usa crédito; recarrega quando quiser |
| **Admin** | Painel da owner: dashboard, reservas, clientes, serviços, descontos, pagamentos, créditos | Owner controla o negócio |
| **Audit** | PaperTrail: histórico de alterações | Owner audita mudanças |

---

## 1. Auth

### O que faz
- Cadastro de dentista (email/senha ou Google OAuth); owner criado apenas via seed.
- Login, logout, recuperação de senha; role (`owner` | `dentist`) rege as autorizações.
- Após login, owner é redirecionado para `/admin`, dentista para a home.

### Arquivos
```
app/controllers/auth/{sessions,registrations,omniauth_callbacks}_controller.rb
app/models/user.rb          ← Devise + enum role string + has_paper_trail + avatar (Active Storage)
app/models/clinic.rb        ← tenant root
app/models/current.rb       ← Current.clinic via ENV["CLINIC_ID"] ou Clinic.first
app/policies/user_policy.rb
app/views/auth/…            ← telas Login/Cadastro com tabs
```

### Decisões importantes
- Rotas Devise em português: `/entrar`, `/sair`, `/cadastro` (sem prefixo `/users`).
- `users.clinic_id` é **nullable** — o cadastro associa à `Current.clinic`.
- Email da dentista não é editável pelo admin (strong params sem `:email`).

---

## 2. Scheduling

### O que faz
- **Owner:** CRUD de `Availability` em `/admin/disponibilidade` (+ toggle bloquear/liberar).
- **Dentista:** vê slots na home (`pages#home`), adiciona ao carrinho (`session[:cart_ids]`), confirma em `/reservas/confirmar`, acompanha em `/reservas`.
- **Cancelamento:** PATCH `/reservas/:id/cancelar` respeitando `CANCELLATION_LEAD_HOURS` (48h).

### Arquivos
```
app/controllers/pages_controller.rb               ← home pública com calendário
app/controllers/scheduling/carts_controller.rb    ← add/remove/clear na sessão
app/controllers/scheduling/bookings_controller.rb ← new/create (confirmar), index, show, cancel
app/models/{availability,booking,booking_group,discount_rule,service}.rb
app/services/{discount_calculator,booking_group_creator,booking_canceller}.rb
app/javascript/controllers/{calendar,book_slot}_controller.js
```

### Fluxo de reserva
```
Home → carrinho (sessão) → /reservas/confirmar (resumo + desconto + crédito)
  → POST → BookingGroupCreator:
      transaction { lock! slots → re-valida → cria group + bookings →
                    abate créditos FIFO → InfinitePay::CheckoutCreator → Payment }
  → redirect para checkout InfinitePay (ou confirmação direta se crédito cobre 100%)
```

### Edge cases críticos (em vigor)
| Caso | Tratamento |
|---|---|
| Duas dentistas disputam o mesmo slot | `lock!` na transação + índice único parcial em `bookings.availability_id` |
| Slot do carrinho reservado por outra | Service re-valida dentro da transação e retorna falha amigável |
| Carrinho vazio no checkout | Redirect com alert |
| Cancelamento < 48h | `BookingCanceller` recusa com mensagem |
| Race webhook × expiração | `confirm!`/`expire!` são no-ops fora do estado `pending` |

---

## 3. Payments (InfinitePay)

### O que faz
- Cria link de checkout hospedado (`POST /links`) e redireciona o dentista.
- Recebe o webhook (`POST /webhooks/infinitepay`) e confirma reserva, recarga **ou** pagamento de diferença (mesmo endpoint — distingue pelo `order_nsu`: `booking_groups`, `credit_purchases` ou `payments`).
- Tela de retorno `/pagamento/retorno` com fallback `InfinitePay::PaymentChecker` se o webhook atrasar.
- Expira pagamentos pendentes via `ExpirePaymentsJob` (sidekiq-cron, 5 em 5 min).
- Broadcast Turbo Stream (`payment_<id>`) atualiza a tela sem refresh.

### Arquivos
```
app/controllers/payments/payments_controller.rb   ← show, pending, return, cancel
app/controllers/payments/webhooks_controller.rb   ← herda de ActionController::Base
app/services/infinite_pay/{checkout_creator,credit_checkout_creator,difference_checkout_creator,payment_checker}.rb
app/services/payment_confirmer.rb                 ← idempotente + broadcast + mailer
app/services/difference_payment_confirmer.rb      ← confirma pagamento de diferença
app/jobs/expire_payments_job.rb
app/mailers/booking_mailer.rb                     ← confirmation, cancellation, credit_issued
```

### Validação do webhook (estado atual)
O InfinitePay não documenta assinatura HMAC. Hoje validamos: `order_nsu` existe no banco + `capture_method == "pix"` + `paid_amount > 0`. **Pendências (roadmap):** comparar `paid_amount` com o valor esperado e/ou confirmar via `payment_check` antes de marcar como pago.

### Edge cases críticos
| Caso | Tratamento |
|---|---|
| Webhook duplicado | Confirmadores idempotentes (`:already_processed`) |
| Webhook com `order_nsu` desconhecido | Loga warning e responde 200 |
| InfinitePay fora do ar no checkout | Service retorna falha; reserva não é criada (rollback) |
| Dentista paga após expiração | Grupo já `expired` → `PaymentConfirmer` é no-op. Tratamento manual (crédito/estorno) — decisão de produto |
| Webhook atrasa e dentista volta antes | `return` consulta `payment_check` como fallback |

---

## 4. Créditos / Carteira

### O que faz
- **Emissão:** cancelar reserva paga gera `Credit` (sem estorno em dinheiro).
- **Consumo:** checkout abate créditos disponíveis em ordem FIFO; se cobrirem 100%, não há cobrança Pix.
- **Recarga:** dentista compra crédito em `/carteira` → `CreditPurchase` + checkout InfinitePay → `CreditPurchaseConfirmer` cria o `Credit`.
- **Admin:** `/admin/credits` (filtros) e ajuste manual via `add_credit`/`remove_credit` no cliente.

### Arquivos
```
app/models/{credit,credit_purchase}.rb
app/services/{credit_issuer,credit_purchase_confirmer}.rb
app/services/infinite_pay/credit_checkout_creator.rb
app/controllers/users/{wallets,credit_purchases}_controller.rb
app/views/users/wallets/show.html.erb             ← saldo + recarga
```

### Decisões importantes
- Crédito **não expira** (decisão de produto).
- Crédito só é emitido quando o grupo **inteiro** pago é cancelado (proporcional está no backlog).
- `CreditPurchase` pendente hoje **não é expirada** pelo `ExpirePaymentsJob` (pendência no roadmap; não trava slot, só fica registro pendente).

---

## 5. Admin

### O que faz
Painel exclusivo do owner (`Admin::BaseController#require_owner!`, layout `admin`):
- **Dashboard** — KPIs + gráfico SVG de receita (6 meses).
- **Reservas** — listar/filtrar, ver detalhe, **criar reserva manual** (`AdminBookingCreator`), cancelar, **trocar turno** (`AdminBookingSlotChanger`: diferença mais cara consome crédito e cobra o restante via Pix; mais barata gera crédito).
- **Clientes** — CRUD de dentistas (sem editar email) + crédito manual.
- **Serviços, Disponibilidade, Descontos, Pagamentos, Créditos, Clínica.**
- **Sidekiq Web** montado em `/admin/sidekiq` (somente owner).

### Decisões importantes
- Admin é um **role**; a defesa primária é `require_owner!` no BaseController (nem todo recurso tem policy Pundit própria).
- `DiscountRule` usa **soft-delete** (`active: false`) — grupos antigos referenciam a regra.
- Desconto é congelado no `BookingGroup` no momento da criação.
- Valores monetários digitados no admin passam por `price_to_cents` (vírgula → centavos).

---

## 6. Audit

- `has_paper_trail` em User, Availability (skip `:status`), BookingGroup, Booking, Payment, Credit, CreditPurchase, DiscountRule, Clinic.
- `whodunnit` = `current_user.id` ou `"sistema"` (webhook/jobs).
- Histórico renderizado nas telas de detalhe do admin (users, bookings, payments).
- Dentista não vê histórico — somente owner.

---

## Diagrama de dependências

```
                 ┌──────────┐
                 │   Auth   │
                 └────┬─────┘
                      │ current_user / role / Current.clinic
   ┌──────────────────┼──────────────────────┬──────────────┐
   ▼                  ▼                      ▼              ▼
┌──────────┐    ┌──────────┐    ┌──────────────────┐  ┌──────────┐
│Scheduling│───►│ Payments │◄───│Créditos/Carteira │  │  Admin   │
└────┬─────┘    └────┬─────┘    └────────┬─────────┘  └────┬─────┘
     │               │                   │                 │
     └───────────────┴───────────────────┴─────────────────┘
                              ▼
                        ┌──────────┐
                        │  Audit   │ (passivo — observa todos)
                        └──────────┘
```

- **Scheduling** chama **Payments** no checkout e **Créditos** para abater saldo.
- **Payments** confirma reservas (webhook) e recargas de crédito (mesmo webhook).
- **Admin** lê/edita tudo; **Audit** apenas observa.

---

*Mapa funcional alinhado ao código em 2026-06-10.*
