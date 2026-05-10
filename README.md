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
   - Salve e volte para criar as credenciais
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

Reinicie o servidor e o botão **Entrar com Google** estará funcional. Na primeira vez, o Google pode exibir um aviso de app não verificado — clique em **Advanced → Go to Videira Dental (unsafe)**. Isso é esperado em desenvolvimento.

### Para produção

Adicione o domínio real nas credenciais do Google Cloud:

- **Authorized JavaScript origins:** `https://seudominio.com.br`
- **Authorized redirect URIs:** `https://seudominio.com.br/auth/google_oauth2/callback`

E altere o **Publishing status** da consent screen de **Testing** para **In production**.

---

## Configurando o MercadoPago Sandbox

### 1. Criar a aplicação no painel de desenvolvedores

1. Acesse [mercadopago.com.br/developers](https://www.mercadopago.com.br/developers)
2. Faça login com sua conta MercadoPago (ou crie uma)
3. Vá em **Suas integrações → Criar aplicação**
4. Preencha:
   - Nome: `Videira Dental`
   - Modelo de pagamento: **Pagamentos online**
   - Produto: **Checkout API**
5. Clique em **Criar aplicação**

### 2. Obter as credenciais Sandbox

Na sua aplicação, vá em **Credenciais → Credenciais de teste**:

- `MERCADOPAGO_ACCESS_TOKEN` → campo **Access Token** (começa com `TEST-`)
- `MERCADOPAGO_PUBLIC_KEY` → campo **Public Key** (começa com `TEST-`)

### 3. Configurar o Webhook

O MercadoPago exige uma URL HTTPS pública para enviar notificações. Em desenvolvimento, use o [ngrok](https://ngrok.com/download) para expor o localhost:

```bash
ngrok http 3000
# Exemplo de saída: https://abc123.ngrok.io
```

No painel do MercadoPago, vá em **Webhooks → Configurar notificações**:

- URL: `https://abc123.ngrok.io/webhooks/mercadopago`
- Eventos: marque **Pagamentos**
- Salve — o `MERCADOPAGO_WEBHOOK_SECRET` é exibido nessa tela

### 4. Atualizar o `.env`

```bash
MERCADOPAGO_ACCESS_TOKEN=TEST-xxxx-seu-access-token
MERCADOPAGO_PUBLIC_KEY=TEST-xxxx-sua-public-key
MERCADOPAGO_WEBHOOK_SECRET=seu-webhook-secret
```

> O token começando com `TEST-` é detectado automaticamente pelo sistema como sandbox. Nesse modo, o QR Code Pix gerado é fictício e nenhuma cobrança real é realizada.

### Simulando um pagamento aprovado

Após gerar um Pix na aplicação, você pode simular a aprovação pelo painel do MercadoPago em **Atividade → pagamento em teste → Aprovar**. O webhook será disparado e a tela do dentista atualizará em tempo real via Turbo Stream.

### Para produção

Substitua pelas **Credenciais de produção** (sem o prefixo `TEST-`) e configure o webhook com o domínio real da aplicação.

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
