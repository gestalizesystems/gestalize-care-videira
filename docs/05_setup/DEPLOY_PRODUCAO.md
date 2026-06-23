# Deploy em Produção — Videira Clinic

> Como o sistema está hospedado, configurado e como atualizar. Go-live: 2026-06.

---

## Visão geral

| Item | Valor |
|---|---|
| **Plataforma** | Railway (projeto `giving-wisdom`, ambiente `production`) |
| **Repositório** | `github.com/nathashaloppes/Videiraclinicclaude` (branch `main`, deploy automático) |
| **URL pública** | https://www.videiraclinic.com.br |
| **URL Railway** | `videiraclinicclaude-production.up.railway.app` |
| **Plano** | Hobby (~US$ 5/mês mínimo; uso real estimado US$ 10–15/mês) |
| **E-mail** | Resend (API HTTP) — domínio `videiraclinic.com.br` verificado |
| **DNS** | registro.br (zona avançada) |

---

## Arquitetura do deploy

Serviço **único** no Railway, usando o `Dockerfile` do projeto, orquestrado por:

- **`railway.toml`** — define `builder = "DOCKERFILE"` e `startCommand = "bash bin/railway-start.sh"`.
- **`bin/railway-start.sh`** — roda, na ordem: `db:prepare` → `db:seed` (idempotente) → **Sidekiq** (background) → **Puma** (processo principal).

Ou seja, web + worker rodam no mesmo container (mais barato). Recursos do projeto:

- **App** (Puma + Sidekiq)
- **PostgreSQL** (plugin Railway)
- **Redis / Key Value** (plugin Railway) — usado por Sidekiq e ActionCable

> ⚠️ As variáveis de referência `DATABASE_URL` e `REDIS_URL` precisam estar **no serviço** (não em "Shared Variables" do projeto), com os valores `${{Postgres.DATABASE_URL}}` e `${{Redis.REDIS_URL}}`.

---

## Variáveis de ambiente (no serviço do app)

| Variável | Valor / origem |
|---|---|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` |
| `SECRET_KEY_BASE` | gerado com `bin/rails secret` |
| `PORT` | `3000` (Puma usa `ENV["PORT"]`; networking do Railway aponta pra 3000) |
| `APP_HOST` | `www.videiraclinic.com.br` |
| `RESEND_API_KEY` | chave `re_...` do Resend |
| `MAILER_FROM` | `Videira Clinic <nao-responda@videiraclinic.com.br>` |
| `INFINITEPAY_HANDLE` | `videiraclinic` (sem o `$`) |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | credenciais OAuth do Google Cloud |
| `OWNER_EMAIL` | e-mail do admin criado pelo seed |
| `OWNER_PASSWORD` | senha do admin (só usada na criação) |
| `CANCELLATION_LEAD_HOURS` | `48` (default) |
| `PAYMENT_EXPIRY_MINUTES` | `30` (expiração do Pix no lado do app) |

`RAILS_ENV=production` já vem do `Dockerfile`. **Não** é necessário `RAILS_MASTER_KEY` (segredos via ENV).

---

## E-mail (Resend)

**Por que não SMTP:** o Railway **bloqueia portas SMTP de saída** (587/465/25) → Gmail SMTP dá `Net::OpenTimeout`. Por isso usamos a **API HTTP do Resend** (porta 443).

- Gem: `resend`; `config/initializers/resend.rb` (`Resend.api_key = ENV["RESEND_API_KEY"]`).
- `config/environments/production.rb`: `config.action_mailer.delivery_method = :resend`.
- Remetente só pode ser do **domínio verificado** (`@videiraclinic.com.br`) — não funciona com `@gmail.com`.
- Verificação do domínio: registros **SPF (TXT), MX (`send`), DKIM, DMARC** adicionados no registro.br.
- Logs de envio: painel do Resend → **Logs**.

---

## Domínio

- `www.videiraclinic.com.br` → CNAME (no registro.br, zona avançada) apontando para o alvo do Railway + TXT `_railway-verify`.
- O registro.br **não permite CNAME na raiz**, então o domínio **pelado** (`videiraclinic.com.br`) não é usado. Para habilitá-lo, seria necessário migrar o DNS para a Cloudflare (CNAME flattening). Decisão atual: **usar só `www`**.
- HTTPS é automático (Railway emite o certificado).

---

## Google OAuth (login com Google)

- Tela de consentimento **publicada** (produção) e escopos básicos (`email`, `profile`).
- **Redirect URI autorizada** (deve bater exatamente): `https://www.videiraclinic.com.br/auth/google_oauth2/callback`.
- O cliente OAuth precisa ser o mesmo do `GOOGLE_CLIENT_ID` configurado no Railway.
- Erro comum: `redirect_uri_mismatch` = URI cadastrada no Google diferente da enviada pelo app (atenção ao `www`).

---

## Como atualizar (deploy)

Deploy é **automático** a cada push na branch `main` do repositório conectado.

```bash
git push videiraclinic main   # dispara build + deploy no Railway
```

O `bin/railway-start.sh` roda as **migrations pendentes** (`db:prepare`) automaticamente no boot. Não há passo manual de migração.

**Redeploy manual:** no serviço → aba **Deployments** → ⋮ no último → **Redeploy** (ou clique em **Apply changes** após editar variáveis).

---

## Diagnóstico (gotchas já enfrentados)

| Sintoma nos Deploy Logs | Causa / correção |
|---|---|
| `Missing secret_key_base for 'production'` | `SECRET_KEY_BASE` ausente/não aplicado no serviço |
| `Database URL cannot be empty` | `DATABASE_URL` estava em Shared Variables (referência não resolve) → mover para o serviço |
| `Net::OpenTimeout` no `net-smtp` | porta SMTP bloqueada pelo Railway → usar Resend (já configurado) |
| `Application failed to respond` (502) | porta errada → `PORT=3000` + target 3000 no Networking |

---

## Pendências de produção

- **Banco:** se o Postgres estiver no plano que expira, migrar para um plano pago antes de operar com dados reais.
- **Backup do banco:** configurar antes de ter dados de clientes.
- **Domínio pelado:** opcional, via Cloudflare (ver seção Domínio).
