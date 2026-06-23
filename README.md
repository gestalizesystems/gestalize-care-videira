# Videira Dental Clinic

[![CI](https://github.com/iandersonf/videira-dental/actions/workflows/ci.yml/badge.svg)](https://github.com/iandersonf/videira-dental/actions/workflows/ci.yml)

Sistema SaaS para aluguel de salas odontológicas. Dentistas buscam horários disponíveis, montam um carrinho com múltiplos slots e pagam via Pix em uma única transação. A clínica gerencia tudo pelo painel administrativo.

---

## Índice

- [Funcionalidades](#funcionalidades)
- [Stack](#stack)
- [Rodando localmente](#rodando-localmente)
- [Configurando o Google OAuth 2.0](#configurando-o-google-oauth-20)
- [Integração com Google Agenda (Owner)](#integração-com-google-agenda-owner)
- [Configurando o InfinitePay](#configurando-o-infinitepay)
- [E-mails transacionais (SMTP)](#e-mails-transacionais-smtp)
- [Testes](#testes)
- [CI — GitHub Actions](#ci--github-actions)
- [Deploy em produção](#deploy-em-produção)
  - [Visão geral](#visão-geral)
  - [Arquitetura do deploy (serviço único)](#arquitetura-do-deploy-serviço-único)
  - [1. Criar o projeto na Railway](#1-criar-o-projeto-na-railway)
  - [2. Variáveis de ambiente](#2-variáveis-de-ambiente)
  - [3. Domínio e HTTPS](#3-domínio-e-https)
  - [4. Deploys seguintes e operação](#4-deploys-seguintes-e-operação)
  - [Backups](#backups)
- [Arquitetura resumida](#arquitetura-resumida)
- [Troubleshooting](#troubleshooting)
- [Variáveis de ambiente completas](#variáveis-de-ambiente-completas)

---

## Funcionalidades

- **Agendamento** — listagem de horários por dia, carrinho por sessão, checkout com desconto automático por volume de slots
- **Pagamento Pix** — integração com o **InfinitePay Checkout**; o dentista é redirecionado ao checkout hospedado e paga via Pix
- **Confirmação em tempo real** — webhook do InfinitePay + Turbo Streams confirmam a reserva e atualizam a tela sem refresh
- **Expiração automática** — `ExpirePaymentsJob` (Sidekiq + sidekiq-cron, a cada 5 min) libera slots de pagamentos não concluídos
- **Créditos / carteira** — cancelamento de reserva paga gera crédito em conta (sem estorno), abatido automaticamente em compras futuras
- **Recarga de créditos** — o dentista compra crédito via Pix na carteira (`CreditPurchase` + `InfinitePay::CreditCheckoutCreator`); o webhook confirma e emite o crédito
- **Painel Admin** — gestão de clínica, dentistas, serviços, horários, regras de desconto, reservas (incluindo criação manual e troca de turno com cobrança/crédito da diferença de preço), pagamentos e créditos
- **E-mails transacionais** — confirmação, cancelamento e emissão de crédito via `BookingMailer`
- **Autenticação** — Devise + login social Google OAuth 2.0
- **Auditoria** — histórico completo de alterações com PaperTrail

---

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Ruby on Rails 7.2 |
| Banco de dados | PostgreSQL (UUIDs via pgcrypto) |
| Frontend | Hotwire (Turbo + Stimulus) + Tailwind CSS |
| JS | Importmap (sem Node/bundler) |
| Background jobs | Sidekiq 7 + Redis + sidekiq-cron |
| Realtime | Turbo Streams via Action Cable (Redis) |
| Pagamentos | InfinitePay Checkout API (Pix) |
| Auth | Devise + OmniAuth Google OAuth 2.0 |
| Autorização | Pundit |
| Auditoria | PaperTrail |
| Paginação | Pagy |
| Testes | RSpec + FactoryBot + Faker + Shoulda-Matchers + WebMock + Capybara |
| Qualidade | RuboCop (omakase) + Brakeman |
| Deploy | Railway (Docker, serviço único) |

---

## Rodando localmente

### Pré-requisitos

- **Ruby 3.2.3** (ver `.ruby-version`)
- **PostgreSQL** (com seu usuário do sistema como superuser — ver passo 3)
- **Redis** (necessário para Sidekiq e Turbo Streams)

> O Tailwind roda via binário standalone (`tailwindcss-rails`) e o JS via Importmap — **não é necessário Node.js**.

### 1. Instalar dependências

```bash
bundle install
```

### 2. Configurar variáveis de ambiente

```bash
cp .env.example .env
```

Para subir a aplicação localmente, as variáveis mínimas são:

| Variável | Descrição |
|---|---|
| `REDIS_URL` | URL do Redis (padrão: `redis://localhost:6379/0`) |
| `SECRET_KEY_BASE` | Gere com `bin/rails secret` e cole no `.env` |
| `OWNER_PASSWORD` | Senha do usuário owner criado pelo seed |

Variáveis opcionais em dev (necessárias para os fluxos completos):

| Variável | Quando precisa |
|---|---|
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Para o login com Google funcionar |
| `INFINITEPAY_HANDLE` | Para o fluxo de pagamento Pix funcionar |
| `APP_HOST` | Domínio público (ex: `localhost:3000`, ou a URL do ngrok ao testar webhook) |

> Sem `INFINITEPAY_HANDLE` você consegue navegar e testar todo o app, exceto a criação do checkout de pagamento. Sem as credenciais do Google, o botão "Entrar com Google" exibirá erro.

### 3. Criar e migrar o banco de dados

O projeto usa autenticação peer do PostgreSQL — nenhuma senha é necessária em desenvolvimento, basta que seu usuário do sistema tenha permissão de superuser:

```bash
sudo -u postgres createuser $USER --superuser  # execute apenas uma vez
bin/rails db:create db:migrate db:seed
```

O seed cria a clínica, um usuário **owner** (`owner@videiradental.com.br` com a senha de `OWNER_PASSWORD`), salas, turnos de exemplo e regras de desconto.

### 4. Subir os serviços

```bash
bin/dev
```

O `bin/dev` (via `Procfile.dev` + foreman) inicia em paralelo:

- **web** — servidor Rails
- **css** — compilador Tailwind em watch
- **worker** — Sidekiq (jobs e expiração de pagamentos)

> Requer Redis rodando. Se preferir terminais separados, rode `bin/rails server`, `redis-server` e `bundle exec sidekiq -C config/sidekiq.yml` em janelas diferentes.

### 5. Acessar

| URL | Descrição |
|---|---|
| http://localhost:3000 | Aplicação principal |
| http://localhost:3000/admin | Painel administrativo (owner) |
| http://localhost:3000/admin/sidekiq | Monitor de jobs (owner) |

---

## Configurando o Google OAuth 2.0

### 1. Criar o projeto no Google Cloud Console

1. Acesse [console.cloud.google.com](https://console.cloud.google.com)
2. Clique em **Select a project → New Project**
3. Dê um nome (ex: `Videira Dental`) e clique em **Create**

### 2. Ativar a API do Google

1. No menu lateral: **APIs & Services → Library**
2. Busque por **Google Identity** e clique em **Enable**

### 3. Criar as credenciais OAuth

1. Vá em **APIs & Services → Credentials**
2. Clique em **+ Create Credentials → OAuth client ID**
3. Se solicitado, configure a **OAuth consent screen** primeiro:
   - User Type: **External**
   - App name: `Videira Dental`
   - Support email: seu e-mail
4. Application type: **Web application**
5. Em **Authorized redirect URIs**, adicione:
   ```
   http://localhost:3000/auth/google_oauth2/callback
   ```
6. Clique em **Create** — você receberá o **Client ID** e o **Client Secret**

### 4. Atualizar o `.env`

```bash
GOOGLE_CLIENT_ID=SEU_CLIENT_ID.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=SEU_CLIENT_SECRET
```

Reinicie o servidor. Na primeira vez, o Google pode exibir aviso de app não verificado — clique em **Advanced → Go to Videira Dental (unsafe)**. É esperado em desenvolvimento.

### Para produção

Adicione o domínio real nas credenciais:

- **Authorized JavaScript origins:** `https://seudominio.com.br`
- **Authorized redirect URIs:** `https://seudominio.com.br/auth/google_oauth2/callback`

E altere o **Publishing status** da consent screen de **Testing** para **In production**.

---

## Integração com Google Agenda (Owner)

> ✅ **Status: implementado.** A owner conecta a própria agenda pelo painel admin
> (Dashboard → **Conectar Google Agenda**), e a sincronização passa a funcionar automaticamente.

**Objetivo:** quando uma reserva é **confirmada** (pagamento aprovado **ou** quitada por crédito),
criar automaticamente **um evento por turno** na **Google Agenda da owner**, com o nome da dentista
e a sala. Cancelamentos removem o evento correspondente.

### Como está implementado
- **Conexão (uma vez):** `Admin::GoogleCalendarController` faz o OAuth offline e guarda o
  `refresh_token` em `users.google_refresh_token` (só a owner).
- **Sincronização:** `GoogleCalendar::EventSyncer` + `GoogleCalendarSyncJob` (assíncrono, com retry).
- **Hooks:** `BookingGroup` (confirma → cria eventos) e `Booking` (cancela → remove evento).
  Cada evento criado guarda seu id em `bookings.google_event_id`.
- **Seguro:** enquanto a owner não conecta a agenda, tudo é no-op (não afeta reservas).

### O que configurar no Google Cloud (uma vez)
1. **Ativar a Google Calendar API** no projeto (APIs & Services → Library → Enable).
2. **Adicionar o escopo** `https://www.googleapis.com/auth/calendar.events` na tela de consentimento.
3. **Adicionar a redirect URI:** `https://www.videiraclinic.com.br/admin/google_calendar/callback`.
4. Como `calendar.events` é escopo **sensível**, adicione a owner como **Test user** (evita
   verificação do app para um único usuário interno).

Variável opcional: `GOOGLE_CALENDAR_ID` (padrão `primary` — a agenda principal da owner).

<details><summary>Desenho original (referência)</summary>

### Como vai funcionar

A owner autoriza o app a escrever na agenda dela **uma vez** (consentimento OAuth com acesso offline). O app guarda o *refresh token* da owner e, a cada confirmação, insere o evento via Google Calendar API. Reusa o mesmo `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` do login.

```
Pagamento confirmado → PaymentConfirmer
        │
        ▼
GoogleCalendar::EventCreator  (usa o refresh token da owner)
        │
        ▼
Evento na agenda da owner: "Aluguel — Dra. Fulana"
  início = availability.date + starts_at
  fim    = availability.date + ends_at
```

### 1. Habilitar a Google Calendar API

No [Google Cloud Console](https://console.cloud.google.com) → **APIs & Services → Library**, busque **Google Calendar API** e clique em **Enable** (no mesmo projeto do OAuth).

### 2. Adicionar o escopo de calendário

Na **OAuth consent screen → Scopes**, adicione:

```
https://www.googleapis.com/auth/calendar.events
```

E garanta, na configuração do OmniAuth, o acesso offline (para receber o *refresh token*):

```ruby
# config/initializers/devise.rb (ou omniauth) — A IMPLEMENTAR
config.omniauth :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],
  scope: "email,profile,https://www.googleapis.com/auth/calendar.events",
  access_type: "offline",
  prompt: "consent"
```

### 3. Variáveis de ambiente

```bash
# Agenda de destino da owner — use "primary" para a agenda principal
# ou o ID de uma agenda dedicada (ex.: reservas@videiradental.com.br)
GOOGLE_CALENDAR_ID=primary
```

> Reusa `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` já existentes. O *refresh token* da owner é guardado no banco (campo a criar em `users`), **não** em variável de ambiente.

### 4. O que falta no código (resumo da implementação)

- Migration: `users.google_refresh_token` (e opcionalmente `google_calendar_event_id` em `bookings`)
- Capturar e salvar o *refresh token* no `Auth::OmniauthCallbacksController` quando a owner autoriza
- Service `GoogleCalendar::EventCreator` / `EventRemover` (gem `google-apis-calendar_v3`)
- Hook em `PaymentConfirmer` (criar evento) e `BookingCanceller` (remover evento)

</details>

---

## Configurando o InfinitePay

Documentação oficial: [infinitepay.io/checkout-documentacao](https://www.infinitepay.io/checkout-documentacao).
Notas de integração do projeto: [`docs/02_arquitetura/INFINITEPAY.md`](docs/02_arquitetura/INFINITEPAY.md).

O InfinitePay funciona como **checkout hospedado**: o app cria um link de pagamento e **redireciona** o dentista para a página do InfinitePay, onde ele paga via Pix. Não há QR Code inline nem countdown na tela do app.

### 1. Obter o InfiniteTag (handle)

1. Acesse [app.infinitepay.io](https://app.infinitepay.io) e faça login
2. Vá em **Perfil** e localize seu **InfiniteTag** (começa com `$`)
3. Use o valor **sem o símbolo `$`** como `INFINITEPAY_HANDLE`

### 2. Definir `APP_HOST` (webhook + redirect)

O webhook e a URL de retorno são montados dinamicamente a partir de `APP_HOST`. Em desenvolvimento, para receber o webhook de confirmação, exponha o localhost com [ngrok](https://ngrok.com/download):

```bash
ngrok http 3000
# saída de exemplo: https://abc123.ngrok.io
```

```bash
# .env
INFINITEPAY_HANDLE=seu-handle-sem-cifrao
APP_HOST=abc123.ngrok.io   # ou localhost:3000 se não for testar o webhook
```

O sistema usará automaticamente:
- Webhook: `https://<APP_HOST>/webhooks/infinitepay`
- Retorno: `https://<APP_HOST>/pagamento/retorno`

### Fluxo de pagamento

1. Dentista confirma a reserva → o app cria o link no InfinitePay (`InfinitePay::CheckoutCreator`)
2. Dentista clica em **Pagar via Pix** e vai ao checkout do InfinitePay
3. Pagamento via **Pix** é realizado
4. InfinitePay envia o webhook → `PaymentConfirmer` confirma a reserva e dispara Turbo Stream
5. Dentista é redirecionado para `/pagamento/retorno`; se o webhook ainda não chegou, o app consulta o status (`InfinitePay::PaymentChecker`) como fallback

> **Migration necessária:** a integração troca as colunas de Pix do MercadoPago por `checkout_url`. Em um banco existente, rode `bin/rails db:migrate` para aplicar `ReplaceMercadopagoWithInfinitepay`.

### Para produção

Defina `APP_HOST` com o domínio real (ex: `videiradental.com.br`). Nenhuma configuração adicional é necessária no painel do InfinitePay — webhook e redirect vão em cada cobrança.

---

## E-mails transacionais

`BookingMailer` (confirmação, cancelamento, crédito) e os e-mails do Devise (confirmação de
conta, reset de senha) são enviados em produção.

> ✅ **Em produção usamos o [Resend](https://resend.com) (API HTTP)**, porque o Railway **bloqueia
> portas SMTP de saída**. Config: `delivery_method = :resend`, `RESEND_API_KEY` + `MAILER_FROM`
> (remetente no domínio verificado `@videiraclinic.com.br`). Ver [`docs/05_setup/DEPLOY_PRODUCAO.md`](docs/05_setup/DEPLOY_PRODUCAO.md).

O código ainda suporta **SMTP** (`config/environments/production.rb` via `SMTP_*`) como alternativa
caso a hospedagem não bloqueie as portas. Em desenvolvimento os e-mails não são enviados de verdade.

---

## Testes

```bash
bundle exec rspec
```

A suíte cobre models, services, requests e system specs (Capybara) — **148 exemplos**.

```bash
bin/rubocop      # estilo (omakase)
bin/brakeman     # análise de segurança
```

---

## CI — GitHub Actions

O workflow `.github/workflows/ci.yml` roda em todo push para `main` e em pull requests.

| Job | O que faz |
|---|---|
| `scan_ruby` | Análise de segurança com Brakeman |
| `scan_js` | Auditoria de dependências JS via `importmap audit` |
| `lint` | Estilo com RuboCop |
| `test` | Suíte RSpec completa com PostgreSQL e Redis como services |

O CI não precisa de secrets para rodar — usa credenciais mock (`INFINITEPAY_HANDLE`, Google) e sobe PostgreSQL e Redis como services do próprio GitHub Actions.

---

## Deploy em produção

> ✅ **Em produção (go-live 2026-06), o sistema roda na [Railway](https://railway.app).**
> Este README traz uma visão geral; o **guia completo e atual** (hospedagem, domínio
> `www.videiraclinic.com.br`, e-mail via Resend, todas as variáveis e diagnóstico de erros)
> está em **[`docs/05_setup/DEPLOY_PRODUCAO.md`](docs/05_setup/DEPLOY_PRODUCAO.md)**.

O projeto inclui um `Dockerfile` de produção e o **`railway.toml`** já versionados. O deploy é
feito na **Railway**, conectada ao repositório no GitHub: cada `push` na branch `main` dispara
um novo build e deploy automaticamente. PostgreSQL e Redis são **plugins gerenciados** da Railway.

### Visão geral

```
┌─ GitHub (branch main) ─┐   push    ┌─ Railway (projeto) ───────────────┐
│ Dockerfile             │ ───────▶  │ • App  (Puma + Sidekiq)           │
│ railway.toml           │  deploy   │ • PostgreSQL (plugin)             │
│ bin/railway-start.sh   │  automát. │ • Redis / Key Value (plugin)      │
└────────────────────────┘           │ • Domínio + HTTPS automático      │
                                      └───────────────────────────────────┘
```

### Arquitetura do deploy (serviço único)

Para economizar, **web e worker rodam no mesmo container**. O boot é orquestrado por:

- **`railway.toml`** — `builder = "DOCKERFILE"` e `startCommand = "bash bin/railway-start.sh"`.
- **`bin/railway-start.sh`** — executa, na ordem: `db:prepare` → `db:seed` (idempotente) →
  **Sidekiq** (em background) → **Puma** (processo principal na porta `$PORT` = 3000).

Não há passo manual de migração: as migrations pendentes rodam no boot (`db:prepare`).

> Este app **não usa Rails credentials** (é 100% movido a ENV), então **não precisa de
> `RAILS_MASTER_KEY` nem de `config/master.key`**. `RAILS_ENV=production` já vem do `Dockerfile`.

### 1. Criar o projeto na Railway

1. Em [railway.app](https://railway.app), **New Project → Deploy from GitHub repo** e selecione o repositório.
2. A Railway detecta o `Dockerfile`/`railway.toml` e cria o serviço do app.
3. No projeto, **add plugin → PostgreSQL** e **add plugin → Redis** (Key Value).

### 2. Variáveis de ambiente

Defina as variáveis **no serviço do app** (não em "Shared Variables"). As de banco/redis usam
referências da Railway:

| Variável | Valor / origem |
|---|---|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` |
| `SECRET_KEY_BASE` | gere com `bin/rails secret` |
| `PORT` | `3000` |
| `APP_HOST` | `www.videiraclinic.com.br` |
| `RESEND_API_KEY` | chave `re_...` do Resend |
| `MAILER_FROM` | `Videira Clinic <nao-responda@videiraclinic.com.br>` |
| `INFINITEPAY_HANDLE` | seu handle (sem o `$`) |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | credenciais OAuth do Google Cloud |
| `OWNER_EMAIL` / `OWNER_PASSWORD` | admin criado pelo seed |
| `CANCELLATION_LEAD_HOURS` | `48` (opcional) |
| `PAYMENT_EXPIRY_MINUTES` | `30` (opcional) |

> ⚠️ As referências `${{Postgres.DATABASE_URL}}` e `${{Redis.REDIS_URL}}` **só resolvem se
> estiverem no serviço**. Em "Shared Variables" do projeto elas ficam vazias → `Database URL cannot be empty`.

**E-mail:** a Railway **bloqueia portas SMTP de saída** (587/465/25), então usamos a **API HTTP
do Resend** (porta 443) em vez de SMTP. Detalhes em `DEPLOY_PRODUCAO.md`.

### 3. Domínio e HTTPS

No serviço → **Settings → Networking → Custom Domain**, adicione `www.videiraclinic.com.br` e
crie no DNS (registro.br) o **CNAME** apontando para o alvo informado pela Railway. O **HTTPS é
automático** (a Railway emite o certificado). O domínio pelado depende de CNAME na raiz (não
suportado pelo registro.br) — por isso usamos só o `www`.

### 4. Deploys seguintes e operação

```bash
git push origin main   # dispara build + deploy automático na Railway
```

- **Logs / console:** painel da Railway → serviço → **Deployments / Logs**.
- **Redeploy manual:** aba **Deployments** → ⋮ no último → **Redeploy**.
- **Health check:** `curl https://www.videiraclinic.com.br/up`.
- **Migrations:** rodam sozinhas no boot (`db:prepare`); para algo pontual, use o
  terminal/Shell do serviço na Railway (`bin/rails ...`).

### Backups

O **PostgreSQL é gerenciado pela Railway**. Antes de operar com dados reais de clientes:

- Confirme que o plano do banco **não expira** (migre para um plano pago se necessário).
- Configure **backups** do Postgres (snapshots da Railway ou `pg_dump` periódico).
- Os uploads do Active Storage (avatares/logo) ficam no volume do serviço — inclua-os na rotina de backup.

---

## Arquitetura resumida

```
app/
├── controllers/
│   ├── scheduling/        # Carrinho e reservas (dentista)
│   ├── payments/          # Pagamento Pix, retorno e webhook InfinitePay
│   ├── users/             # Perfil e carteira
│   ├── auth/              # Sessions, registrations, OAuth callbacks
│   └── admin/             # Painel administrativo
├── services/
│   ├── booking_group_creator.rb     # Cria reserva + pagamento em transação atômica (FOR UPDATE)
│   ├── booking_canceller.rb         # Valida regra de 48h, libera o slot e emite crédito
│   ├── discount_calculator.rb       # Aplica a melhor regra de desconto por volume
│   ├── credit_issuer.rb             # Emite crédito ao cancelar reserva paga
│   ├── payment_confirmer.rb         # Confirma pagamento e faz broadcast Turbo
│   └── infinite_pay/                # CheckoutCreator, PaymentChecker
├── jobs/
│   └── expire_payments_job.rb       # Expira pagamentos pendentes a cada 5 min (sidekiq-cron)
└── models/
    ├── booking_group.rb   # Agrupa N bookings sob 1 pagamento
    ├── availability.rb    # Slot de horário (turno) da sala
    ├── payment.rb         # Registro de pagamento (checkout_url InfinitePay)
    └── credit.rb          # Crédito em conta do dentista
```

**Fluxo de pagamento:**

1. Dentista adiciona horários ao carrinho (`session[:cart_ids]`)
2. Checkout cria `BookingGroup` + `Booking`s + `Payment` numa única transação com `FOR UPDATE` (evita double-booking); créditos disponíveis são abatidos
3. Se restar valor a pagar, `InfinitePay::CheckoutCreator` gera o link e o dentista é redirecionado ao checkout
4. InfinitePay envia o webhook → `PaymentConfirmer` confirma reserva e pagamento
5. Turbo Stream atualiza a tela do dentista em tempo real

---

## Troubleshooting

### `PG::ConnectionBad: FATAL: role "usuario" does not exist`

Seu usuário do sistema não tem permissão no PostgreSQL:

```bash
sudo -u postgres createuser $USER --superuser
```

### `Redis::CannotConnectError: Error connecting to Redis`

O Redis não está rodando:

```bash
redis-server
# ou: sudo systemctl start redis
```

### `KeyError: key not found: "INFINITEPAY_HANDLE"`

O fluxo de pagamento foi acionado sem o handle no `.env`. Defina `INFINITEPAY_HANDLE` e reinicie o servidor.

### Webhook do InfinitePay não chega em desenvolvimento

O InfinitePay precisa de uma URL HTTPS pública. Use o [ngrok](https://ngrok.com/download) e atualize `APP_HOST` no `.env` com o domínio gerado (muda a cada sessão na versão gratuita). Reinicie o servidor após alterar.

### `ActionController::InvalidAuthenticityToken` no webhook

O webhook não envia token CSRF. Isso já está tratado em `Payments::WebhooksController` com `protect_from_forgery with: :null_session`. Confirme que a rota é `POST /webhooks/infinitepay`.

### Login com Google redireciona para erro

- Verifique `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` no `.env`
- Confirme que `http://localhost:3000/auth/google_oauth2/callback` está nos **Authorized redirect URIs**
- Reinicie o servidor após alterar o `.env`

### Pagamentos não expiram

A expiração roda no Sidekiq via sidekiq-cron (`ExpirePaymentsJob`, a cada 5 min). Garanta que o Sidekiq está rodando (`bin/dev` já o inicia, desde que o Redis esteja ativo).

### Assets não compilam / Tailwind não atualiza

Suba com `bin/dev` (não `bin/rails server`) — ele inicia o compilador do Tailwind em paralelo.

### Reservas ficam presas em "aguardando pagamento" / horários não são liberados

O Sidekiq (worker) não está rodando. O `ExpirePaymentsJob` é responsável por expirar pagamentos vencidos e liberar os horários — ele roda via cron a cada 5 minutos, mas só funciona com o Sidekiq ativo.

**Em desenvolvimento:** suba sempre com `bin/dev` (não `bin/rails server`). O `Procfile.dev` inclui `worker: bundle exec sidekiq`.

**Em produção (Railway):** web e Sidekiq sobem no mesmo container via `bin/railway-start.sh`
(o Sidekiq é iniciado em background antes do Puma). Confira nos **Deploy Logs** do serviço se há
a linha de boot do Sidekiq; se faltar, verifique se `REDIS_URL` está configurado **no serviço**
(`${{Redis.REDIS_URL}}`).

Para processar manualmente os pagamentos acumulados, use o terminal/Shell do serviço na Railway:

```bash
bin/rails runner "ExpirePaymentsJob.perform_now"
# ou, localmente:
bundle exec rails runner "ExpirePaymentsJob.perform_now"
```

---

### `bin/rails db:seed` falha com e-mail duplicado

O seed já foi rodado. Recrie o banco:

```bash
bin/rails db:drop db:create db:migrate db:seed
```

---

## Variáveis de ambiente completas

Veja [`.env.example`](.env.example) para a lista completa com descrições. Resumo:

| Variável | Dev | Prod | Default |
|---|:---:|:---:|---|
| `DATABASE_URL` | — (peer auth) | ✅ | — |
| `REDIS_URL` | ✅ | ✅ | `redis://localhost:6379/0` |
| `SECRET_KEY_BASE` | ✅ | ✅ (secret) | — |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | opcional | ✅ | — |
| `INFINITEPAY_HANDLE` | opcional | ✅ | — |
| `APP_HOST` | ✅ | ✅ | `localhost:3000` / `videiradental.com.br` |
| `OWNER_PASSWORD` | ✅ | ✅ | — |
| `CANCELLATION_LEAD_HOURS` | opcional | opcional | `48` |
| `PAYMENT_EXPIRY_MINUTES` | opcional | opcional | `30` |
| `MAILER_FROM` | — | opcional | `no-reply@videiradental.com.br` |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USERNAME` / `SMTP_PASSWORD` | — | ✅ | — |
