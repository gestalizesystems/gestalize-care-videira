# Videira Dental Clinic — FONTE_DA_VERDADE.md

> **Documento master.** Substitui o CONTEXT.md.
> Fonte única e canônica do projeto. Todo o resto (ARQUITETURA, BANCO_DE_DADOS, MODULOS, ROADMAP_TECNICO) detalha pontos específicos consistentes com este documento.
> Última atualização: 2026-05-09

---

## ⚠️ Status (2026-06-10): spec histórica — a implementação divergiu

Este documento é a **spec original** e permanece válido como visão de produto. Mas a implementação evoluiu em pontos importantes. Para o estado atual, consulte `ARQUITETURA.md`, `BANCO_DE_DADOS.md` e `MODULOS.md` (auditados em 2026-06-10). Divergências principais:

| Spec original | Implementação real | Motivo |
|---|---|---|
| MercadoPago + QR Pix inline | **InfinitePay Checkout** (link hospedado, redirect) | Troca de gateway; ver `INFINITEPAY.md` |
| Model `Room` (1 sala por clínica) | Não existe — `Service` (tipo de turno) + `Availability` direto na clínica | Modelo de turno/serviço representa melhor o negócio |
| Money `decimal(10,2)` | **Centavos** (`*_cents` integer) + concern `MoneyConvertible` | Evita erros de arredondamento |
| Enums integer | **Enums string** + check constraint no Postgres | Banco legível; constraint protege fora do Rails |
| Ruby 3.3 | **Ruby 3.2.3** (`.ruby-version`) | Versão disponível no ambiente |
| Sem créditos | Sistema de **créditos** (cancelamento) + **recarga via Pix** (`CreditPurchase`) | Evolução de produto pós-MVP |
| Rotas `/conta`, `/minhas-reservas`, controllers `users/` | `/perfil`, `/carteira`, `/reservas`, namespaces `auth/`, `scheduling/`, `payments/`, `users/` | Reorganização na implementação |

---

## 1. Definição do projeto

**Videira Dental Clinic (VDC)** é uma plataforma SaaS web para **aluguel de sala odontológica**. A dona da clínica (uma dentista proprietária) cria janelas de disponibilidade da sala e define o preço de cada uma. Outras dentistas, clientes da plataforma, navegam essa agenda, selecionam um ou mais slots, fazem checkout em lote com **um único QR Code Pix** (com possível desconto por quantidade) e, ao pagar, têm a reserva confirmada.

**Não é** um sistema de consultas, de gestão de pacientes, nem de venda de produtos. **É** um sistema de aluguel de espaço com pagamento por uso.

Sobre o codinome **AgendaKit**: é o nome do template Rails reutilizável que nasce da implementação do VDC. AgendaKit não é um produto separado — é a arquitetura do VDC vista como template. Nenhuma decisão pode aumentar a complexidade do VDC para "preparar o AgendaKit". Se algo é útil pro AgendaKit, deve ser útil pro VDC primeiro.

---

## 2. Stack final (validada e congelada)

| Componente | Tecnologia | Por que |
|---|---|---|
| Linguagem / framework | **Ruby 3.3 + Rails 7.2** | Velocidade de entrega; projeto solo |
| Frontend | **Hotwire (Turbo + Stimulus)** | Sem SPA; sem API JSON separada |
| CSS | **Tailwind CSS** | Mesmo sistema do Figma; tradução direta |
| Banco | **PostgreSQL com pgcrypto** | UUIDs nativos; multi-tenant futuro |
| Auth | **Devise + omniauth-google-oauth2** | Email/senha + Google login |
| Autorização | **Pundit** | Simples, explícito, testável |
| Auditoria | **PaperTrail** | Histórico nativo Rails, sem esforço |
| Pagamento | **MercadoPago Pix** | Único provedor com Pix nativo no Brasil |
| Jobs | **Sidekiq + Redis + sidekiq-cron** | Expiração crítica de pagamentos |
| Paginação | **pagy** | Rápido, sem mágica |
| Upload | **ActiveStorage + image_processing** | Avatar da dentista |
| Testes | **RSpec + FactoryBot + Faker** | Cobertura de fluxos críticos |

> **Não usar:** React, Stripe, Supabase, Vercel.
> **Decisão fechada:** o sistema é **fullstack monolítico Rails**. Qualquer proposta de "vamos extrair API" para uma fase posterior precisa de justificativa de produto, não de arquitetura.

---

## 3. Atores e roles

| Role | Quem | Como entra na plataforma |
|---|---|---|
| `owner` | Dona da clínica (Cibele Videira). 1 por clínica no MVP. | Criada via seeds/console. **Não há cadastro público.** |
| `dentist` | Dentistas que alugam a sala. N por clínica. | Auto-cadastro: email/senha **ou** Google OAuth |

Default de role no auto-cadastro: `:dentist`. Um usuário **nunca** muda de role pela UI.

---

## 4. Regras de negócio (sem ambiguidade)

### 4.1 Sala (Room)

- 1 clínica → **1 sala** no MVP (forçado por `unique index` em `rooms.clinic_id`).
- A dona controla 100% da disponibilidade.

### 4.2 Disponibilidade (Availability)

- A owner cria slots informando: `date`, `starts_at`, `ends_at`, `price`.
- O preço é **definido por slot**, **pela owner**. Não há preço padrão.
- Validação: `ends_at > starts_at` (Ruby + check Postgres).
- Validação: `price > 0` (Ruby + check Postgres).
- Slots podem ser criados com várias datas/horários, mas sempre 1 por vez via UI (sem batch create no MVP).
- `booked: false` por default. Vira `true` quando um booking pendente é criado (hold).

### 4.3 Carrinho

- Persiste em `session[:cart_ids]` (array de UUID strings).
- Anônimas podem montar carrinho. Para checkout, login obrigatório.
- Carrinho **não merge** entre sessões; cada sessão é isolada.
- Limpo ao concluir checkout (`session.delete(:cart_ids)`).

### 4.4 Reserva (Booking) e Grupo (BookingGroup)

- Toda reserva nasce como parte de um `BookingGroup` (mesmo se for 1 slot).
- `BookingGroup.status`: `pending` → `confirmed` (pago) | `expired` (não pago) | `cancelled` (todos os bookings cancelados pela dentista).
- `Booking.status`: `pending` → `confirmed` (pago) | `cancelled` (manual ou expiração).
- Ao criar o group, todas as `Availability`s envolvidas têm `booked: true` (hold). Se o pagamento expira, voltam a `false`.
- Defesa contra concorrência:
  1. `lock!` (`SELECT FOR UPDATE`) nas availabilities dentro da transação.
  2. Unique index em `bookings.availability_id` — Postgres rejeita double-booking mesmo se o lock falhar.

### 4.5 Pagamento (Payment)

- **Provedor exclusivo:** MercadoPago (Pix).
- **Um único** Payment por BookingGroup (forçado por unique index).
- **Janela de expiração:** `ENV['PAYMENT_EXPIRATION_MINUTES']`, default 30 min.
- O QR e o código copia-e-cola vêm do MercadoPago. O `pix_qr_url` armazena o **base64 PNG** retornado em `qr_code_base64` (apesar do nome). Renderizado como `<img src="data:image/png;base64,…">`.
- **Webhook** valida assinatura HMAC com `ENV['MERCADOPAGO_WEBHOOK_SECRET']` antes de processar.
- **Idempotência:** `PaymentConfirmer` é no-op se o group já está `confirmed` ou `expired`.
- **Job de expiração:** `ExpirePaymentsJob` roda a cada 5 min via sidekiq-cron.

### 4.6 Desconto por quantidade (DiscountRule)

- Configurado pela owner (sem hardcode). CRUD em `/admin/descontos`.
- Cada regra: `min_slots` (≥ 2) e `discount_percent` (∈ (0, 100]). Forçado por check Postgres.
- `min_slots` é **único** por clínica (unique index `(clinic_id, min_slots)`) — não pode haver duas regras conflitantes.
- O sistema aplica a **maior `min_slots` que cabe na quantidade**: `DiscountRule.best_for(quantity, clinic)`.
- Cálculo:
  ```
  subtotal        = sum(availabilities.price)
  discount_percent = best_rule.discount_percent (ou 0)
  discount_amount  = round(subtotal * discount_percent / 100, 2)
  total            = subtotal - discount_amount
  ```
- `total = subtotal - discount_amount` é forçado por **check constraint** Postgres.
- Desconto é "frozen" no momento da criação do BookingGroup. Mudanças posteriores na regra não afetam grupos antigos.
- **Soft-delete:** `Admin::DiscountRulesController#destroy` apenas seta `active: false`. Hard delete quebraria FKs em booking_groups antigos.

### 4.7 Cancelamento

- Apenas a **dentista que criou** o booking pode cancelar (Pundit `cancel?`).
- Apenas bookings com status `confirmed` podem ser cancelados (`pending` aguardando pagamento, ou `cancelled`/`expired`, não).
- **Antecedência mínima:** `ENV['CANCELLATION_LEAD_HOURS']`, default 48h.
- Verificação:
  ```ruby
  slot_at = Time.zone.local(date.year, date.month, date.day, starts_at.hour, starts_at.min)
  slot_at > CANCELLATION_LEAD_HOURS.hours.from_now
  ```
- `cancel_reason` é **obrigatório** ao cancelar (validação no controller + service).
- Ao cancelar:
  - `booking.status = :cancelled`, `cancelled_at = now`, `cancel_reason = reason`.
  - `availability.booked = false` (libera para outras dentistas).
  - Se **todos** os bookings do mesmo BookingGroup estão cancelados, o `BookingGroup.status = :cancelled` (sentinela).
- **Política de reembolso:** **fora de escopo do MVP.** Cancelamento libera o slot mas **não** estorna pagamento. Documentado para a dona tratar manualmente caso ocorra.

### 4.8 Edição de dados pelo owner

- Owner pode editar dados das dentistas: `name`, `phone`, `cro_number`, `specialty`, `birth_date`.
- Owner **não pode** editar `email` (campo blindado em strong params).
- A dentista mesma pode editar: `name`, `phone`, `specialty`, `birth_date`, `avatar` em `/conta`.
- Para alterar `email`, a dentista usa o fluxo Devise padrão (`registrations#edit`) — disponibilizado em fase 2.
- Toda edição (de qualquer origem) é gravada no PaperTrail com `whodunnit = current_user.id`.

### 4.9 Auditoria (PaperTrail)

| Entidade | Campos rastreados |
|---|---|
| `User` | Tudo, exceto Devise técnicos (`encrypted_password`, `*_token`, `sign_in_*`) |
| `Availability` | Tudo exceto `booked` (sem valor de auditoria) |
| `DiscountRule` | Tudo |
| `Booking` | Tudo |
| `BookingGroup` | Tudo |
| `Payment` | Apenas `status`, `amount`, `paid_at`, `expires_at` |

- `whodunnit` armazena o **UUID do user** como string. Quando vazio, "Sistema".
- Histórico visível **apenas para owner** em `/admin/clientes/:id` e `/admin/reservas/:id`.

### 4.10 Multi-tenant

- `clinic_id` em **todas** as entidades de domínio principais.
- Toda Pundit `Scope.resolve` filtra por `user.clinic`.
- MVP atende **uma clínica** (`Clinic.first` é referência implícita em `HomeController` e `OmniauthCallbacksController`). Quando expandir, esses 2 pontos passam a buscar a clinic via slug/subdomínio.

---

## 5. ERD canônico

```
Clinic        (1) ── (N) User
              (1) ── (1) Room
              (1) ── (N) DiscountRule
              (1) ── (N) BookingGroup

Room          (1) ── (N) Availability

User(owner)   (1) ── (N) Availability    [created_by]
User(dentist) (1) ── (N) BookingGroup
User(dentist) (1) ── (N) Booking

BookingGroup  (1) ── (N) Booking
BookingGroup  (N) ── (0..1) DiscountRule
BookingGroup  (1) ── (1) Payment

Availability  (1) ── (0..1) Booking      [unique]

Version       (N) ── (loose link via item_type, item_id, whodunnit)
```

Para o ERD detalhado e migrations, ver **BANCO_DE_DADOS.md**.

---

## 6. Fluxos completos

### 6.1 Happy path: agendamento único

```
1. Owner cria Availability (date, starts_at, ends_at, price).
2. Dentista (anônima ou logada) abre / e seleciona um slot.
3. Click "Adicionar ao carrinho" (POST /carrinho/adicionar).
4. Click "Pagar com Pix" → se anônima, redirect para login.
5. GET /reservas/confirmar — DiscountCalculator (sem desconto, 1 slot).
6. POST /reservas → BookingGroupCreator:
   - lock! da availability
   - cria BookingGroup (subtotal, total, status: :pending)
   - cria Booking (status: :pending)
   - marca availability.booked = true
   - chama MercadoPago::PixCreator → cria Payment com QR code
7. Redirect para /pagamento/<payment.id>.
8. Dentista escaneia QR ou copia o "copia-e-cola" Pix.
9. Paga no app do banco.
10. MercadoPago dispara webhook POST /webhooks/mercadopago.
11. WebhookValidator valida HMAC. PaymentConfirmer roda.
12. BookingGroup#confirm! → group + booking + payment vão para confirmed/paid.
13. Turbo Stream broadcast atualiza /pagamento/<id> para mostrar confirmação verde.
```

### 6.2 Happy path: agendamento em lote (com desconto)

```
1-4. Igual ao anterior, mas selecionando 5 slots.
5. GET /reservas/confirmar — DiscountCalculator aplica regra "5 slots → 15%".
   - subtotal = sum(prices)
   - discount_percent = 15.0
   - discount_amount = round(subtotal * 0.15, 2)
   - total = subtotal - discount_amount
6-13. Iguais. Pix gerado para o total com desconto. Webhook confirma todos os 5 bookings.
```

### 6.3 Sad path: pagamento expira

```
1-7. Igual. Dentista chega em /pagamento/<id> mas não paga.
8. 30 minutos passam.
9. ExpirePaymentsJob (sidekiq-cron, a cada 5 min) detecta:
   Payment.expiring → status pending + expires_at < now
10. Para cada payment:
    - guard: skip se group.confirmed? (race com webhook)
    - BookingGroup#expire! → group + bookings + payment vão para expired/cancelled
    - availabilities voltam a booked: false
11. Turbo Stream broadcast para a tela mostrar "Pagamento expirado".
```

### 6.4 Sad path: cancelamento (48h)

```
1. Dentista logada em /minhas-reservas vê reserva confirmed.
2. Click "Cancelar" no booking individual.
3. Modal pede cancel_reason (obrigatório).
4. PATCH /bookings/:id/cancel.
5. Pundit BookingPolicy#cancel? — apenas dona do booking + status confirmed.
6. BookingCanceller:
   - Availability#cancellable? checa lead time (48h)
   - Se NÃO: raise TooLate. Controller mostra alert "Cancelamento exige 48h".
   - Se SIM: transação atualiza booking + libera availability + (talvez) cancela group.
7. Redirect para /minhas-reservas com notice de sucesso.
8. Slot volta a ficar disponível para outras dentistas (Home reflete na próxima visita).
```

### 6.5 Sad path: race no checkout

```
1. Dentista A e dentista B selecionam o mesmo slot S no carrinho.
2. Ambas clicam "Pagar com Pix" simultaneamente.
3. BookingGroupCreator (A) entra em transação, lock!(S), cria booking_A, S.booked = true.
4. BookingGroupCreator (B) tenta entrar — lock! aguarda.
5. (A) commita. (B) recebe lock, recarrega S, vê booked: true.
6. (B) raise SlotTaken. Service retorna Result(success: false, error: "Slot indisponível").
7. Controller (B) faz redirect_to root_path com alert.
8. Defesa adicional: se algo falhar, unique index em bookings.availability_id rejeita o INSERT.
```

### 6.6 Sad path: webhook duplicado / atrasado

```
1. MercadoPago confirma pagamento e dispara webhook.
2. WebhooksController processa. PaymentConfirmer.call → group.confirm!.
3. MercadoPago retenta (rede instável) e dispara webhook de novo 30s depois.
4. PaymentConfirmer roda de novo.
5. group.confirmed? === true → return :already_confirmed (no-op).
6. head :ok. Sem efeito colateral.
```

---

## 7. Mapa de telas e rotas

### Públicas

| Rota | Action | Tela |
|---|---|---|
| `GET /` | `home#index` | Home com agenda de slots |
| `GET /login` | `devise/sessions#new` | Login (email/senha + Google) |
| `GET /cadastro` | `devise/registrations#new` | Cadastro de dentista |
| `POST /webhooks/mercadopago` | `webhooks#mercadopago` | Webhook MP (sem auth, sem CSRF) |

### Carrinho (anônimo permitido)

| Rota | Action |
|---|---|
| `POST /carrinho/adicionar` | `cart#add` |
| `DELETE /carrinho/remover` | `cart#remove` |
| `DELETE /carrinho/limpar` | `cart#clear` |

### Dentista autenticada

| Rota | Action | Tela |
|---|---|---|
| `GET /conta` | `users#show` | Perfil |
| `PATCH /conta` | `users#update` | Salvar perfil |
| `GET /minhas-reservas` | `bookings#index` | Histórico |
| `GET /reservas/confirmar` | `booking_groups#new` | Resumo do checkout |
| `POST /reservas` | `booking_groups#create` | Criar BookingGroup |
| `GET /reservas/:id` | `booking_groups#show` | Detalhe do grupo |
| `GET /pagamento/:id` | `payments#show` | QR Code Pix + status |
| `GET /bookings/:id` | `bookings#show` | Detalhe de booking |
| `PATCH /bookings/:id/cancel` | `bookings#cancel` | Cancelar |

### Painel Owner

| Rota | Action |
|---|---|
| `GET /admin` | redirect → `/admin/reservas` |
| `GET /admin/disponibilidade` | `admin/availabilities#index` |
| `POST /admin/disponibilidade` | `admin/availabilities#create` |
| `GET /admin/disponibilidade/:id/edit` | `admin/availabilities#edit` |
| `PATCH /admin/disponibilidade/:id` | `admin/availabilities#update` |
| `DELETE /admin/disponibilidade/:id` | `admin/availabilities#destroy` |
| `GET /admin/reservas` | `admin/bookings#index` |
| `GET /admin/reservas/:id` | `admin/bookings#show` |
| `PATCH /admin/reservas/:id` | `admin/bookings#update` |
| `GET /admin/clientes` | `admin/users#index` |
| `GET /admin/clientes/:id` | `admin/users#show` |
| `PATCH /admin/clientes/:id` | `admin/users#update` |
| `GET /admin/descontos` | `admin/discount_rules#index` |
| `POST /admin/descontos` | `admin/discount_rules#create` |
| `GET /admin/descontos/:id/edit` | `admin/discount_rules#edit` |
| `PATCH /admin/descontos/:id` | `admin/discount_rules#update` |
| `DELETE /admin/descontos/:id` | `admin/discount_rules#destroy` (soft-delete) |

---

## 8. Convenções de código (resumo)

> Detalhado em **ARQUITETURA.md §4**.

- **Ruby:** 2 espaços, aspas duplas, métodos curtos, guard clauses, sem `frozen_string_literal`.
- **Rails:** convention over configuration. Models magros, services para fluxos cross-model, controllers RESTful.
- **ERB:** sem inline `<style>`/`<script>`. Tailwind utility classes via tema (não cores hex inline). Partials em `shared/` quando reusados.
- **Stimulus:** 1 controller por arquivo, kebab-case na referência HTML, snake_case no nome do arquivo.
- **Tailwind:** cores nomeadas em `tailwind.config.js`, classes na ordem layout → spacing → typography → color → state.
- **I18n:** pt-BR default; toda mensagem de UI traduzida.
- **Paths:** em português (`/conta`, `/minhas-reservas`, `/admin/disponibilidade`).
- **Migrations:** check constraints sempre que houver invariante; índices justificados no nome.
- **Comentários:** apenas para o "porquê" não-óbvio.

---

## 9. Variáveis de ambiente

```bash
# Banco
DATABASE_URL=postgresql://localhost/videira_dental_development

# MercadoPago
MERCADOPAGO_ACCESS_TOKEN=TEST-xxxx
MERCADOPAGO_PUBLIC_KEY=TEST-xxxx
MERCADOPAGO_WEBHOOK_SECRET=xxxx

# Google OAuth
GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxx

# App
APP_HOST=http://localhost:3000
APP_DEFAULT_TIMEZONE=America/Sao_Paulo
SECRET_KEY_BASE=
REDIS_URL=redis://localhost:6379/0

# Regras de negócio configuráveis sem deploy
PAYMENT_EXPIRATION_MINUTES=30
CANCELLATION_LEAD_HOURS=48

# Seed (dev only)
OWNER_EMAIL=videiraclinic@gmail.com
OWNER_PASSWORD=ChangeMe!2026
```

---

## 10. Decisões técnicas registradas

| # | Decisão | Por que |
|---|---|---|
| 1 | Hotwire em vez de React | Sem API JSON, sem state global, projeto solo |
| 2 | UUID em todas as PKs | Multi-tenant, segurança, padrão SaaS |
| 3 | MercadoPago em vez de Stripe | Único provedor com Pix nativo no Brasil |
| 4 | Pix em vez de cartão | Sem taxas de cartão, instantâneo, sem antifraude complexo |
| 5 | `BookingGroup` agrega bookings | Um único Pix por compra; desconto em lote |
| 6 | `Payment` pertence a `BookingGroup` | Consequência de 5 |
| 7 | `price` em `Availability` (não `Clinic`) | Owner define preço por slot livremente |
| 8 | `DiscountRule` configurável | Sem hardcode; flexibilidade para a dona |
| 9 | `clinic_id` em todas as entidades | Multi-tenant desde o MVP |
| 10 | `paper_trail` em entidades críticas | Auditoria sem esforço |
| 11 | Cancelamento = 48h | Decisão de produto (CONTEXT original) |
| 12 | Pagamento expira em 30 min | Padrão de mercado para Pix |
| 13 | Soft-delete de `DiscountRule` | Preserva integridade de booking_groups antigos |
| 14 | Hard-delete de `Availability` permitido só se `!booked` | Owner pode "limpar" agenda futura |
| 15 | Single-room por clínica no MVP | Forçado por `unique index` em `rooms.clinic_id` |
| 16 | Carrinho em `session` (não cookie persistido entre dispositivos) | MVP simples; suficiente |
| 17 | Sem confirmação de email no Devise | Onboarding mais rápido |
| 18 | RSpec adicionado depois (apesar de `--skip-test`) | Cobertura é necessária mesmo em MVP solo |
| 19 | Idempotência em `PaymentConfirmer` e `ExpirePaymentsJob` | Webhooks duplicam; jobs podem reexecutar |
| 20 | Validação HMAC do webhook MP | Segurança básica obrigatória |

---

## 11. Faq — perguntas frequentes com respostas definitivas

### Modelagem

**P: Posso adicionar um campo de "tipo de procedimento" ao Booking?**
R: **Não.** O VDC aluga sala. Não rastreia procedimentos. Adicionar isso muda o domínio.

**P: O `Booking` precisa de `total` próprio? Em vez de só no `BookingGroup`?**
R: **Não.** Pagamento é sempre no nível do grupo. `Booking.availability.price` é a referência se precisar inspecionar valor unitário.

**P: Por que `BookingGroup` se um BookingGroup pode ter 1 só Booking?**
R: Para uniformizar pagamento e desconto. Reservar 1 ou 5 slots tem o **mesmo fluxo**.

**P: Posso fazer multi-room agora?**
R: **Não.** O `unique index` em `rooms.clinic_id` força MVP single-room. Quando precisar, drop do índice + ajuste no `HomeController` (`Clinic.first.rooms` em vez de `room`). 1h de trabalho. Não fazer especulativamente.

**P: Como adicionar uma segunda clínica?**
R: Quando o momento chegar: criar via console (`Clinic.create!`); ajustar `HomeController#index` e `OmniauthCallbacksController` para resolver clínica por slug/subdomínio em vez de `Clinic.first`. Resto do código já está escopado por `clinic_id`.

### Pagamento

**P: O `pix_qr_url` deveria ter um `_url` no nome se armazena base64?**
R: **Concordo, mas mantemos** por compatibilidade com o código existente. Documentado em **BANCO_DE_DADOS.md §3.10** que armazena base64 PNG. Renomeação fica para refator futuro.

**P: E se a dentista pagar fora da janela de 30 min e o webhook chegar depois?**
R: O `BookingGroup` já está `:expired` quando o webhook chega. `PaymentConfirmer` retorna `:already_expired` (no-op). **Decisão de produto:** loga incident e envia email para `owner_email` para tratamento manual (estorno via MP painel). Não é tratado pelo sistema.

**P: Posso permitir cartão de crédito além de Pix?**
R: **Não no MVP.** Aumenta superficie de risco, exige antifraude, mais views, mais testes. Decidido em CONTEXT 6.6.

**P: Por que `MercadoPago::PixCreator` retorna hash em vez de OpenStruct?**
R: Para manter compatibilidade com o `BookingGroupCreator`. Padronização (todas para OpenStruct) fica para refator.

### Cancelamento

**P: A dentista pode cancelar um BookingGroup inteiro de uma vez?**
R: **Sim, mas indiretamente.** Cancela cada Booking; quando todos forem cancelados, `BookingGroup` vai para `:cancelled` automaticamente. Não há botão "cancelar grupo".

**P: 48h é hard-coded?**
R: **Não.** É `ENV['CANCELLATION_LEAD_HOURS']`, default 48. A dona pode mudar sem deploy de código.

**P: Reembolso é automático?**
R: **Não no MVP.** Cancelamento libera o slot mas não estorna. Owner trata manualmente via painel MP.

### Auth

**P: Owner pode ser auto-cadastrado?**
R: **Não.** Owner é criado via seeds/console. Não há tela pública para isso. (Se houver UI futura, ficará em `/admin` e exigirá owner já existente para criar outro owner — pattern "first owner via seed".)

**P: A dentista pode mudar o próprio email?**
R: **Sim**, via fluxo Devise (`/users/edit`). Fora do MVP visual mas o endpoint funciona. Owner **não pode** mudar email da dentista.

**P: Múltiplas dentistas podem usar a mesma conta Google?**
R: **Não.** Unique partial index em `users.google_uid` (where not null) garante 1 conta Google = 1 user.

### Auditoria

**P: A dentista vê histórico das próprias alterações?**
R: **Não no MVP.** Histórico é restrito ao owner.

**P: Versions crescem indefinidamente?**
R: **Sim no MVP.** Em escala, criar job de purge para versions > 1 ano.

### Frontend

**P: Posso usar React/Vue/Svelte para uma tela específica?**
R: **Não.** Hotwire resolve. Se um caso real exigir SPA pesado, reabrir a discussão com proposta concreta.

**P: Confetti na confirmação de pagamento?**
R: **Opcional, fase 2.** Stimulus + canvas-confetti. Não bloqueia MVP.

**P: Drag-and-drop de slots no admin?**
R: **Não.** Ordenação é por `starts_at`. Drag-and-drop é Figma-React, não cabe na UX Rails.

**P: Por que tem `style="..."` inline em alguns exemplos do DESIGN_SYSTEM.md?**
R: Foi a tradução literal do Figma. **Convenção definitiva:** **migrar para Tailwind utility classes** com cores nomeadas em `tailwind.config.js`. `style` inline só quando o valor vem do banco (ex: cor dinâmica de um slot).

### Concorrência

**P: O que acontece se 2 dentistas reservam o mesmo slot ao mesmo tempo?**
R: Defesa em 2 camadas: (1) `lock!` na transação; (2) unique index em `bookings.availability_id`. Uma das dentistas recebe "Slot indisponível"; a outra completa o checkout.

**P: E se o webhook chega 2x?**
R: `PaymentConfirmer` é idempotente. `return :already_confirmed if group.confirmed?`.

**P: E se o job de expiração roda enquanto o webhook está em transação?**
R: Ambos checam `pending?` antes de mudar. O primeiro que commit ganha. O outro vira no-op.

### Deploy

**P: Onde fazer deploy?**
R: **Render** (recomendado para começar) ou Fly.io ou Railway. Heroku evitar (preço subiu). Não Vercel (não suporta Rails server-side bem).

**P: Preciso de Redis em produção?**
R: **Sim.** Sidekiq (job de expiração) exige.

### Geral

**P: Posso adicionar feature X que não está no documento?**
R: **Não sem alinhamento.** Toda feature nova exige update da FONTE_DA_VERDADE.md primeiro.

**P: Posso refatorar arquivo Y para padrão Z?**
R: Se a arquitetura documentada permite, sim. Se conflita, abrir discussão **antes** do refator.

**P: O CONTEXT.md ainda existe?**
R: **Não.** Foi substituído por este documento. Histórico do CONTEXT permanece em git para referência, mas qualquer fonte da verdade deste momento em diante é **FONTE_DA_VERDADE.md**.

---

## 12. Como usar este documento com IA

### ✅ Forma correta

```
Use FONTE_DA_VERDADE.md como fonte da verdade do projeto Videira Dental Clinic.
Use ARQUITETURA.md, BANCO_DE_DADOS.md, MODULOS.md e ROADMAP_TECNICO.md como
detalhamento técnico consistente com a fonte da verdade.

Tarefa: [descrever tarefa específica].

Restrições:
- Stack: Rails 7.2 + Hotwire + Tailwind + PostgreSQL (não inventar)
- MercadoPago Pix exclusivamente (não Stripe, não cartão)
- UUIDs em todas as PKs
- 48h de antecedência para cancelamento
- paper_trail em todas as entidades críticas
```

### ❌ Forma incorreta

```
Faz a tela de pagamento aí
```

---

## 13. Documentos do projeto (mapa)

| Documento | O que tem |
|---|---|
| **FONTE_DA_VERDADE.md** | (este) — fonte canônica: definição, regras, fluxos, FAQ |
| **ARQUITETURA.md** | estrutura de pastas, camadas, convenções, layouts, routes |
| **BANCO_DE_DADOS.md** | schema, migrations, índices, constraints, ERD, seeds |
| **MODULOS.md** | mapa funcional dividido em 5 módulos com edge cases |
| **ROADMAP_TECNICO.md** | tarefas em ordem, com prompts prontos para IA |
| **DESIGN_SYSTEM.md** | tokens visuais, componentes ERB, tradução React→Rails |
| **VSCODE_SETUP.md** | configuração do editor |
| **README.md** | introdução do ZIP |

CONTEXT.md original: **arquivado** — não usar como fonte primária.

---

*Fonte da verdade definitiva. Toda mudança de regra de negócio começa por uma edição aqui.*
