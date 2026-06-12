# Videira Dental Clinic — CONTEXT.md
> Documento histórico de contexto. Alimentava as interações com IA na fase de construção.
> Combina especificação original (vdc_final) com decisões e correções da época.
> Última atualização: Maio 2026

> ⚠️ **Status (2026-06-10):** documento **histórico**. Pontos como MercadoPago/QR inline, model `Room`, money decimal e enums integer **não refletem mais o código**. Para o estado atual use: `FONTE_DA_VERDADE.md` (visão de produto + tabela de divergências), `ARQUITETURA.md`, `BANCO_DE_DADOS.md` e `MODULOS.md`.

---

## 1. Definição do Projeto

**Videira Dental Clinic (VDC)** é uma plataforma web de aluguel de sala odontológica com agendamento online e pagamento via Pix integrado. Construída sobre Rails 7.2 com Hotwire — sem React, sem SPA separado.

> O produto é simultaneamente um negócio operacional para a Videira Dental Clinic e um template validado (AgendaKit) para projetos SaaS futuros.

---

## 2. Visão Estratégica

| Camada | O que é | Objetivo |
|--------|---------|----------|
| **Produto** | Sistema de agendamento + pagamento | Negócio real e funcional |
| **Arquitetura** | Template Rails reutilizável | Base para próximos SaaS |
| **IA Copiloto** | LibreChat + Ollama local | Acelerar todos os projetos futuros |

---

## 3. Stack Tecnológica

| Componente | Tecnologia | Justificativa |
|------------|-----------|---------------|
| Backend | Ruby on Rails 7.2 (fullstack) | Velocidade de entrega no MVP |
| Frontend | Hotwire (Turbo + Stimulus) | Sem SPA separado, zero camada de API |
| Estilização | Tailwind CSS v4 | Mesmo sistema do Figma |
| Banco de dados | PostgreSQL (UUID via pgcrypto) | Robustez, multi-tenant desde o início |
| Autenticação | Devise + OmniAuth Google | Email/senha + OAuth Google |
| Pagamento | MercadoPago (Pix) | Pix nativo no Brasil |
| Jobs | Sidekiq + Redis + sidekiq-cron | Expiração de pagamentos |
| Deploy | Kamal 2 + Docker + Traefik | VPS com SSL automático |
| CI | GitHub Actions | Brakeman, RuboCop, RSpec |
| Storage | Active Storage (dev: local, prod: S3) | Avatar e logo |
| Realtime | Turbo Streams via Action Cable (Redis) | Atualização de tela sem refresh |

> **Stripe não é utilizado** — não suporta Pix nativamente no Brasil.
> **React não é utilizado** — exigiria API JSON separada para um dev solo.

---

## 4. Gems Rails Essenciais

```ruby
gem 'devise'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'mercadopago'
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'redis'
gem 'pagy'
gem 'dotenv-rails'
gem 'pundit'
gem 'paper_trail'
# Testes
gem 'rspec-rails'
gem 'factory_bot_rails'
gem 'shoulda-matchers'
gem 'webmock'
```

---

## 5. Contexto de Negócio

### Quem é a dona do sistema
- Uma dentista proprietária de uma sala odontológica
- Ela **aluga a sala** para outras dentistas (não oferece consultas)
- Cadastrada manualmente pelo admin (não se registra pela plataforma)
- Role: `owner`

### Quem são os usuários
- **Outras dentistas** que alugam a sala para atender seus próprios pacientes
- Se registram com email/senha ou Google OAuth
- Role: `dentist`

### O único serviço
> **Aluguel de sala odontológica por período (data + horário de início + horário de fim)**

O **valor de cada slot é definido individualmente pela dona** ao criar a disponibilidade.

---

## 6. Regras de Negócio

### 6.1 Autenticação e Roles

| Role | Quem é | Como entra |
|------|--------|------------|
| `owner` | Dona da clínica | Cadastrada pelo admin (seed) |
| `dentist` | Dentista que aluga a sala | Auto-cadastro (email/senha) |

- `owner` tem acesso total ao admin, incluindo `/admin/sidekiq`
- Autorização via Pundit — policies em `app/policies/`
- `authenticate_user!` é default no `ApplicationController`; controllers públicos usam `skip_before_action`

### 6.2 Sala (Room)

- Existe **apenas uma sala** no MVP
- A dona controla 100% da disponibilidade
- Estrutura já suporta múltiplas salas (relação `Clinic → many Rooms`)

### 6.3 Disponibilidade (Availability)

- A dona cria slots com: `date`, `starts_at`, `ends_at`, `price`
- `price` fica no model `Availability` (não em `Clinic`)
- Pode criar para **vários dias à frente** de uma vez
- Slot reservado (`booked: true`) não pode ser agendado por outra dentista

### 6.4 Agendamento (Booking)

- A dentista seleciona **um ou vários slots** e agenda em lote
- Cada slot gera um `Booking` individual (status: `pending`)
- Todos os bookings do lote são agrupados em um `BookingGroup`
- O `BookingGroup` gera **um único QR Code Pix** cobrindo todos
- Booking confirmado (`confirmed`) somente após pagamento aprovado

### 6.5 Cancelamento

- Só é possível cancelar com **pelo menos 48h de antecedência** (não 24h)
- `cancel_reason` é obrigatório ao cancelar
- Ao cancelar, o slot volta a `booked: false`
- Cancelamentos com menos de 48h são bloqueados pelo sistema
- O cancelamento é por **booking individual** — a dentista pode cancelar um slot do lote sem cancelar os demais

### 6.6 Pagamento (Payment)

- Método exclusivo: **Pix via MercadoPago**
- Um único QR Code Pix por `BookingGroup`
- `Payment` pertence ao `BookingGroup` (não ao `Booking` individual)
- `expires_at`: 30 minutos para pagar
- Não pagar → `status: expired`, slots liberados (via Sidekiq job)
- Pagar → webhook MP confirma → `status: paid` → bookings `confirmed`
- `amount` = soma dos `price` dos slots com desconto aplicado

### 6.7 Cancelamento após pagamento → Crédito

Quando uma reserva é cancelada após o pagamento confirmado, **não fazemos estorno no MercadoPago**. Em vez disso, emitimos um **crédito em conta** para o dentista, que pode ser usado para abater futuras reservas. Esta funcionalidade ainda não foi implementada — ver `ATIVIDADES.md`.

### 6.8 Desconto por Quantidade (DiscountRule)

- A dona configura livremente no painel
- Cada regra: **quantidade mínima de slots** + **percentual de desconto**
- O sistema aplica automaticamente a maior regra aplicável
- `BookingGroup` armazena: `subtotal`, `discount_percent`, `discount_amount`, `total`
- Se não houver regra aplicável, nenhum desconto é aplicado

### 6.9 Auditoria (PaperTrail)

Entidades auditadas:

| Entidade | O que é rastreado |
|----------|-------------------|
| `User` | Edições de dados da dentista |
| `Availability` | Criação, edição e desativação |
| `Booking` | Mudanças de status e cancel_reason |
| `BookingGroup` | Mudanças de status e valores |
| `Payment` | Mudanças de status |
| `DiscountRule` | Criação, edição e desativação |

- Somente `owner` acessa o histórico no painel admin
- `whodunnit` registra o usuário logado em cada alteração

### 6.10 Edição de Dados pelo Owner

- Owner pode visualizar e editar dados de qualquer dentista
- Campos editáveis: `name`, `phone`, `cro_number`, `specialty`, `birth_date`
- Email **não pode ser alterado** pelo owner (requer fluxo Devise próprio)
- Toda edição é rastreada pelo PaperTrail

### 6.11 Escalabilidade (Multi-tenant)

- MVP atende **uma clínica** — `Clinic.first` está hardcoded em `PagesController` e `Scheduling::ServicosController`
- Arquitetura usa `clinic_id` em todas as entidades principais desde o início
- Decisão de como escalar para multi-clínica (subdomínio, slug, ENV) ainda não tomada — ver `ATIVIDADES.md`

---

## 7. Modelagem de Dados (ERD)

### Entidades

#### Clinic
```
id              uuid PK
name            string
slug            string (único, ex: "videira-dental")
owner_email     string
created_at      timestamp
```

#### User
```
id                  uuid PK
clinic_id           uuid FK → Clinic
name                string
email               string (único)
encrypted_password  string
google_uid          string (nullable)
phone               string (nullable)
cro_number          string (nullable)
specialty           string (nullable)
birth_date          date (nullable)
avatar_url          string (nullable)
role                enum(string): owner | dentist
created_at          timestamp
updated_at          timestamp
```

#### Room
```
id          uuid PK
clinic_id   uuid FK → Clinic
name        string
description text (nullable)
created_at  timestamp
```

#### Availability
```
id            uuid PK
room_id       uuid FK → Room
created_by    uuid FK → User (owner)
date          date
starts_at     time
ends_at       time
price         decimal
booked        boolean (default: false)
created_at    timestamp
```

#### DiscountRule
```
id                uuid PK
clinic_id         uuid FK → Clinic
min_slots         integer
discount_percent  decimal
active            boolean (default: true)
created_at        timestamp
```

#### BookingGroup
```
id                uuid PK
user_id           uuid FK → User (dentist)
clinic_id         uuid FK → Clinic
discount_rule_id  uuid FK → DiscountRule (nullable)
subtotal          decimal
discount_percent  decimal
discount_amount   decimal
total             decimal
status            enum(string): pending | confirmed | expired
created_at        timestamp
```

#### Booking
```
id                uuid PK
booking_group_id  uuid FK → BookingGroup
availability_id   uuid FK → Availability
user_id           uuid FK → User (dentist)
status            enum(string): pending | confirmed | cancelled
cancel_reason     text (nullable)
cancelled_at      timestamp (nullable)
created_at        timestamp
```

#### Payment
```
id               uuid PK
booking_group_id uuid FK → BookingGroup
provider         string (default: "mercadopago")
provider_id      string (ID da preferência no MP)
pix_code         text
pix_qr_url       string
status           enum(string): pending | paid | expired
amount           decimal
expires_at       timestamp
paid_at          timestamp (nullable)
created_at       timestamp
```

> **Todos os enums são string-backed** (`backed_by_column_of_type(:string)`).

### Relacionamentos

```
Clinic           1 ──── N    User
Clinic           1 ──── 1    Room              (MVP: uma sala)
Clinic           1 ──── N    DiscountRule
Room             1 ──── N    Availability
User(owner)      1 ──── N    Availability
User(dentist)    1 ──── N    BookingGroup
BookingGroup     1 ──── N    Booking
BookingGroup     N ──── 0|1  DiscountRule
Availability     1 ──── 0|1  Booking
BookingGroup     1 ──── 1    Payment
```

---

## 8. Fluxos Principais

### Agendamento + Pagamento (Happy Path)
```
1. Dona cria slots de disponibilidade
2. Dentista seleciona 1 ou mais slots (carrinho via session[:cart_ids])
3. BookingGroupCreator cria BookingGroup + Bookings + Payment em transação atômica (FOR UPDATE)
4. DiscountCalculator aplica melhor regra de desconto
5. MercadoPago::PixCreator gera QR Code Pix
6. Dentista escaneia e paga
7. MercadoPago dispara webhook HMAC-SHA256
8. Webhooks::MercadoPagoController valida → chama PaymentConfirmer
9. PaymentConfirmer: Payment → paid, BookingGroup → confirmed, Bookings → confirmed
10. Turbo Stream atualiza tela do dentista em tempo real
```

### Expiração (Sad Path)
```
1. ExpirePaymentsJob (Sidekiq, a cada 5 min via sidekiq-cron) detecta Payment expirado
2. Payment → expired, BookingGroup → expired
3. Todos os Bookings → cancelled (automático)
4. Todas as Availabilities → booked: false
```

### Cancelamento
```
1. Dentista solicita cancelamento de Booking específico
2. BookingCanceller verifica: faltam mais de 48h?
   → Não: bloqueado com mensagem de erro
   → Sim: pede cancel_reason
3. Booking → cancelled, Availability → booked: false
4. Se todos os Bookings do grupo cancelados → BookingGroup → cancelled
5. Se pagamento já confirmado → emite crédito (não implementado ainda)
```

---

## 9. Decisões Técnicas

| Decisão | Escolha | Motivo |
|---------|---------|--------|
| Frontend | Hotwire (Turbo + Stimulus) | Projeto solo, elimina camada de API |
| Estilização | Tailwind CSS v4 | Mesmo sistema do Figma |
| React | ❌ Não usar | Exigiria API JSON + gerenciamento de estado |
| Auth | Devise + OmniAuth Google | Google OAuth transmite confiança |
| Pagamento | MercadoPago | Único com Pix real no Brasil |
| Stripe | ❌ Não usar | Sem suporte a Pix nativo |
| Primary Key | UUID (pgcrypto) | Segurança, multi-tenant |
| Autorização | Pundit | Simples, explícito, testável |
| Jobs | Sidekiq + Redis + sidekiq-cron | Expiração de pagamento crítica |
| Multi-tenant | clinic_id em todas entidades | Escalar sem reescrever |
| Sala no MVP | Uma por clínica | Simplifica sem comprometer estrutura |
| Agendamento em lote | BookingGroup | Um Pix por grupo |
| Desconto | DiscountRule configurável | Sem hardcode |
| Auditoria | PaperTrail | Histórico completo nativo |
| Deploy | Kamal 2 | Docker em VPS com Traefik |
| Cancelamento pago | Crédito em conta | Sem estorno no MP |
| Enums | string-backed | Legibilidade no banco |

---

## 10. Problemas Resolvidos (não redescobrir)

### PaperTrail — `item_id` deve ser `string`
PaperTrail instalado com migration padrão define `item_id` como `bigint`. Como os models usam UUID, o Rails convertia para `0`, e as queries `user.versions` retornavam vazio.

**Correção:** migration `20260510024824_change_versions_item_id_to_string.rb` converte para `string`. Se recriar o banco do zero, essa migration já está incluída.

### `FOR UPDATE` com `.size` causa erro no PostgreSQL
Em `BookingGroupCreator`, chamar `.size` em uma relation com `lock("FOR UPDATE")` gera `PG::FeatureNotSupported` porque o Rails traduz `.size` para `COUNT(*) FOR UPDATE`.

**Solução:**
```ruby
availabilities = Availability.where(...).lock("FOR UPDATE").load
# .load materializa a collection — .size agora funciona sem nova query
```

### Enums string-backed nos specs
Ao testar com shoulda-matchers, sempre usar:
```ruby
it { is_expected.to define_enum_for(:status).backed_by_column_of_type(:string).with_values(...) }
```

---

## 11. MercadoPago

### Webhook — validação HMAC
`MercadoPago::WebhookValidator` valida assinatura HMAC-SHA256:
```
"id:{id};request-id:{x-request-id};ts:{ts}"
```

### Bypass de validação
Se `MERCADOPAGO_WEBHOOK_SECRET` começar com `mock` ou estiver em branco, o validador retorna `valid: true`. Útil para testes locais.

### Fluxo interno
1. `BookingGroupCreator` → `MercadoPago::PixCreator` → `pix_code` + `payment_id`
2. Dentista vê QR Code + countdown 30 min
3. MP envia `POST /webhooks/mercadopago` com `action: "payment.updated"`
4. `Webhooks::MercadoPagoController` → `MercadoPago::PaymentFinder` → `PaymentConfirmer`
5. `PaymentConfirmer` → broadcast Turbo Stream

---

## 12. Arquitetura de Serviços

Todos os serviços herdam de `ApplicationService` e retornam `ApplicationService::Result`:
```ruby
result = AlgumServico.call(params)
result.success? # => true/false
result.value    # => dado em caso de sucesso
result.error    # => mensagem em caso de falha
```

Serviços existentes:
- `BookingGroupCreator` — cria grupo + Pix (usa FOR UPDATE)
- `BookingCanceller` — cancela booking individual (verifica 48h)
- `DiscountCalculator` — calcula desconto por quantidade
- `PaymentConfirmer` — confirma pagamento + broadcast Turbo
- `MercadoPago::PixCreator` — integra API do MP para gerar Pix
- `MercadoPago::PaymentFinder` — busca pagamento no MP
- `MercadoPago::WebhookValidator` — valida assinatura HMAC

> `PaymentFinder` retorna hash com **chaves string** (`"status"`, `"external_reference"`). Mocks nos specs devem respeitar isso.

---

## 13. Telas e Rotas

### Rotas Públicas

| Rota Rails | View | Descrição |
|------------|------|-----------|
| `GET /` | `home#index` | Agenda de slots disponíveis |
| `GET /login` | `auth/sessions#new` | Login email/senha ou Google OAuth |
| `GET /cadastro` | `auth/registrations#new` | Registro de nova dentista |

### Rotas da Dentista (role: dentist)

| Rota Rails | Descrição |
|------------|-----------|
| `GET /conta` | Perfil: nome, email, telefone, CRO, especialidade, foto |
| `GET /minhas-reservas` | Histórico de BookingGroups + Bookings |
| `GET /reservas/confirmar` | Resumo dos slots selecionados + desconto |
| `GET /pagamento/:id` | QR Code Pix + status (polling via Turbo) |

### Rotas do Painel Owner (role: owner)

| Rota Rails | Descrição |
|------------|-----------|
| `GET /admin/reservas` | Todas as reservas com filtro por data |
| `GET /admin/clientes` | Lista de dentistas cadastradas |
| `GET /admin/clientes/:id` | Detalhes + histórico + PaperTrail |
| `GET /admin/disponibilidade` | Gerenciar slots (criar, editar, desativar) |
| `GET /admin/descontos` | CRUD de regras de desconto |
| `GET /admin/sidekiq` | Monitor de jobs (owner only) |

### Convenções de views Devise
- Views em `app/views/auth/sessions/` e `app/views/auth/registrations/` (controllers são `Auth::*`)
- Views default (passwords, confirmations, unlocks) em `app/views/devise/`

---

## 14. Design System / Restyling (aplicado em 2026-05-13)

- **Mobile-first com `max-w-md` (448px).** Desktop fica para fase posterior.
- **Paleta marrom VDC** — sem azul/cinza Tailwind default: `#5D4037`, `#fef8e1`, `#8D6E63`
- Tokens em `@theme` (Tailwind v4) e `:root` (CSS vars) em `app/assets/tailwind/application.css`
- **Admin sem sidebar** — grid de cards 2-col, mesmo padrão mobile da home
- **Stimulus:** `flash_controller` (auto-dismiss 3s + click), `password_toggle_controller` (olho de senha)
- **Helper:** `booking_group_status_class` + `booking_group_status_style` para cores de status

### Convenção de cor
- Preferir `style="color: #XXXXXX"` inline quando Tailwind utility não cobre o token
- Classes custom (`.text-vdc-*`, `.bg-vdc-*`) disponíveis em `application.css`

### Não coberto (TODO)
- Tema dark mode
- Logo SVG (placeholder "V" em círculo marrom)
- Desktop responsivo — Fase 7 ainda não executada
- Lighthouse audit — executar com `bin/dev` rodando

---

## 15. Convenções de Teste

- Framework: RSpec + FactoryBot + Shoulda-Matchers + WebMock
- Factories em `spec/factories/`
- Mocks de serviços externos com `WebMock.stub_request` ou `allow(Servico).to receive(:call)`
- Turbo broadcasts: `allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)`
- Webhook: payload deve incluir `action: "payment.updated"` para o controller processar
- PaperTrail desabilitado globalmente nos testes por padrão. Para habilitar:
  ```ruby
  describe "PaperTrail", versioning: true do
    # ...
  end
  ```
  Não adicionar hooks manuais `before/after` — o framework já gerencia via `require "paper_trail/frameworks/rspec"`.

---

## 16. O que o Figma tinha e NÃO entra no MVP

| Funcionalidade | Motivo |
|----------------|--------|
| Videira Shop (e-commerce) | Fora do escopo |
| Sistema de Créditos (saldo + transações) | Fora do MVP — pagamento é sempre via Pix |
| Drag-and-drop de turnos | Não aplicável em Hotwire |
| Supabase / LocalStorage | Substituído por PostgreSQL |
| React / Vite / TypeScript | Substituído por Hotwire |
| Deploy Vercel | Rails não roda em Vercel |

---

## 17. O que ainda não foi implementado

Ver `ATIVIDADES.md` para lista completa e priorizada. Resumo:

1. Views de Serviços (admin), Clínica (admin), Perfil do usuário — controllers existem, views não
2. Sistema de créditos — `Credit` model + `CreditIssuer` + abatimento no checkout
3. Emails transacionais — `BookingMailer` não implementado
4. Request specs para admin e fluxo de agendamento

---

## 18. Como Retomar o Desenvolvimento

```bash
git clone git@github.com:iandersonf/videira-dental.git
cd videira-dental
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

Leia `README.md` para setup completo (Google OAuth, MercadoPago, variáveis de ambiente).
Leia `ATIVIDADES.md` para o backlog priorizado.
Leia este arquivo (`CONTEXT.md`) para não redescobrir problemas já resolvidos.

---

## 19. Time Virtual de IA (LibreChat)

### Senior Rails Engineer
> Você é um Senior Rails Engineer especialista em Rails 7+, Hotwire, PostgreSQL e SaaS. Siga os padrões deste CONTEXT.md. Use UUIDs como PKs, Pundit para autorização, Devise para autenticação.

### System Architect
> Você é um arquiteto de sistemas SaaS multi-tenant. Revise decisões de modelagem e arquitetura do VDC. Sempre consulte CONTEXT.md antes de sugerir mudanças. Pense em escalabilidade desde o MVP.

### Code Reviewer
> Você é um code reviewer sênior em Ruby on Rails. Analise buscando: segurança, performance, edge cases, aderência aos padrões. Consulte CONTEXT.md para entender o contexto.

---

*Videira Dental Clinic — documento vivo, atualizar a cada decisão relevante do projeto.*
