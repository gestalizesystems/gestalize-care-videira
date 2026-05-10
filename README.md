# Videira Dental Clinic

[![CI](https://github.com/iandersonf/videira-dental/actions/workflows/ci.yml/badge.svg)](https://github.com/iandersonf/videira-dental/actions/workflows/ci.yml)

Sistema SaaS para aluguel de salas odontológicas. Dentistas buscam horários disponíveis, montam um carrinho com múltiplos slots e pagam via Pix em uma única transação. A clínica gerencia tudo pelo painel administrativo.

---

## Índice

- [Funcionalidades](#funcionalidades)
- [Stack](#stack)
- [Rodando localmente](#rodando-localmente)
- [Configurando o Google OAuth 2.0](#configurando-o-google-oauth-20)
- [Configurando o MercadoPago Sandbox](#configurando-o-mercadopago-sandbox)
- [Testes](#testes)
- [CI — GitHub Actions](#ci--github-actions)
- [Configurando o servidor VPS do zero](#configurando-o-servidor-vps-do-zero)
- [Deploy em produção](#deploy-em-produção)
- [Arquitetura resumida](#arquitetura-resumida)
- [Troubleshooting](#troubleshooting)
- [Variáveis de ambiente completas](#variáveis-de-ambiente-completas)

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

## CI — GitHub Actions

O projeto já vem com um workflow em `.github/workflows/ci.yml` que roda automaticamente em todo push para `main` e em pull requests.

### Jobs executados

| Job | O que faz |
|---|---|
| `scan_ruby` | Análise estática de segurança Rails com Brakeman |
| `scan_js` | Auditoria de dependências JavaScript via importmap |
| `lint` | Verificação de estilo com RuboCop |
| `test` | Roda a suíte RSpec completa com PostgreSQL e Redis reais |

### Configuração necessária

O CI não precisa de nenhuma configuração manual de secrets para rodar — ele usa credenciais mock para Google e MercadoPago, e sobe PostgreSQL e Redis como services do próprio GitHub Actions.

### Adicionando secrets para deploy automático (opcional)

Para configurar o Kamal dentro do CI (deploy automático no merge para `main`), adicione os secrets em **Settings → Secrets and variables → Actions** no repositório:

| Secret | Valor |
|---|---|
| `KAMAL_REGISTRY_PASSWORD` | Senha do Docker Hub |
| `RAILS_MASTER_KEY` | Conteúdo de `config/master.key` |
| `DATABASE_URL` | URL do banco de produção |
| `SECRET_KEY_BASE` | Gerado com `bin/rails secret` |
| `GOOGLE_CLIENT_ID` | Credencial OAuth produção |
| `GOOGLE_CLIENT_SECRET` | Credencial OAuth produção |
| `MERCADOPAGO_ACCESS_TOKEN` | Token de produção MP |
| `MERCADOPAGO_WEBHOOK_SECRET` | Secret do webhook MP |
| `OWNER_PASSWORD` | Senha do owner (seed) |

Depois adicione um job `deploy` ao workflow que rode `kamal deploy` após o job `test` passar.

---

## Configurando o servidor VPS do zero

Antes de rodar o `kamal setup`, o servidor precisa estar acessível via SSH. Siga os passos abaixo.

### 1. Criar o servidor

Escolha um provedor e crie uma instância Ubuntu 22.04 LTS:

| Provedor | Plano recomendado | Custo |
|---|---|---|
| [Hetzner](https://hetzner.com/cloud) | CX22 (2 vCPU / 4 GB) | ~€4/mês |
| [DigitalOcean](https://digitalocean.com) | Droplet 2 vCPU / 2 GB | ~$18/mês |
| [AWS EC2](https://aws.amazon.com/ec2) | t3.small | ~$15/mês |

Na criação, selecione **autenticação por SSH Key** e adicione sua chave pública local (`~/.ssh/id_rsa.pub`).

### 2. Acessar o servidor

```bash
ssh root@SEU_IP
```

### 3. Criar usuário de deploy

Não use `root` para o Kamal. Crie um usuário dedicado:

```bash
adduser deploy
usermod -aG sudo deploy

# Copiar as chaves SSH do root para o novo usuário
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy
```

### 4. Configurar o firewall

```bash
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw enable
ufw status   # deve mostrar as 3 regras ativas
```

### 5. Instalar o Docker

```bash
curl -fsSL https://get.docker.com | sh
usermod -aG docker deploy
```

### 6. Configurar o domínio (DNS)

No painel do seu registrador de domínio (Registro.br, Cloudflare, etc.), crie um registro **A**:

```
Tipo:  A
Nome:  @  (raiz) ou subdomínio (ex: app)
Valor: SEU_IP_DO_SERVIDOR
TTL:   300
```

Aguarde a propagação (5 min a 24h) e verifique:

```bash
dig seudominio.com.br +short
# deve retornar o IP do servidor
```

### 7. Testar conexão com o usuário de deploy

Da sua máquina local:

```bash
ssh deploy@SEU_IP
# se conectar sem pedir senha, está pronto
```

Com isso o servidor está preparado. Siga para a próxima seção.

---

## Deploy em produção

O projeto inclui um `Dockerfile` otimizado para produção. O método recomendado é o **Kamal**, ferramenta de deploy da própria equipe do Rails. Abaixo está o passo a passo completo do zero ao ar.

### Pré-requisitos

**Servidor (VPS):**
- Ubuntu 22.04+ configurado conforme a seção anterior
- Portas 80 e 443 abertas no firewall
- Domínio apontando para o IP do servidor

**Máquina local:**
- Docker instalado e rodando
- Conta no [Docker Hub](https://hub.docker.com) (gratuita)

### 1. Instalar o Kamal (máquina local)

```bash
gem install kamal
```

### 2. Inicializar a configuração do Kamal

```bash
kamal init
```

Isso cria o arquivo `config/deploy.yml`. Configure-o com os dados do seu servidor:

```yaml
# config/deploy.yml
service: videira-dental
image: seu-usuario-dockerhub/videira-dental

servers:
  web:
    - SEU_IP_DO_SERVIDOR
  job:
    hosts:
      - SEU_IP_DO_SERVIDOR
    cmd: bundle exec sidekiq

registry:
  username: seu-usuario-dockerhub
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    REDIS_URL: redis://localhost:6379/0
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE
    - DATABASE_URL
    - GOOGLE_CLIENT_ID
    - GOOGLE_CLIENT_SECRET
    - MERCADOPAGO_ACCESS_TOKEN
    - MERCADOPAGO_PUBLIC_KEY
    - MERCADOPAGO_WEBHOOK_SECRET
    - OWNER_PASSWORD

accessories:
  db:
    image: postgres:16
    host: SEU_IP_DO_SERVIDOR
    env:
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
  redis:
    image: redis:7
    host: SEU_IP_DO_SERVIDOR
    directories:
      - data:/data

proxy:
  ssl: true
  host: seudominio.com.br
```

### 3. Configurar os secrets

Crie o arquivo `.kamal/secrets` (nunca commite esse arquivo — ele já está no `.gitignore`):

```bash
KAMAL_REGISTRY_PASSWORD=sua-senha-dockerhub
RAILS_MASTER_KEY=$(cat config/master.key)
SECRET_KEY_BASE=$(bin/rails secret)
DATABASE_URL=postgresql://postgres:SENHA_POSTGRES@localhost:5432/videira_dental_production
POSTGRES_PASSWORD=SENHA_POSTGRES
GOOGLE_CLIENT_ID=seu-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=seu-client-secret
MERCADOPAGO_ACCESS_TOKEN=APP_USR-seu-token-producao
MERCADOPAGO_PUBLIC_KEY=APP_USR-sua-public-key
MERCADOPAGO_WEBHOOK_SECRET=seu-webhook-secret
OWNER_PASSWORD=SenhaForteOwner2024!
```

### 4. Primeiro deploy

```bash
kamal setup
```

Esse comando executa tudo de uma vez:
1. Faz o build da imagem Docker localmente
2. Envia a imagem para o Docker Hub
3. Instala os containers no servidor (Rails + Sidekiq + PostgreSQL + Redis)
4. Obtém o certificado SSL via Let's Encrypt
5. Roda `db:prepare` (cria e migra o banco automaticamente)

Ao final, a aplicação estará disponível em `https://seudominio.com.br`.

### 5. Deploys subsequentes

A cada nova versão:

```bash
git push origin main  # envia o código
kamal deploy          # build + push + swap sem downtime
```

O Kamal faz o deploy com **zero downtime** — o container antigo só é removido após o novo estar saudável.

### Comandos úteis no dia a dia

```bash
kamal logs                              # logs em tempo real
kamal console                           # Rails console no servidor
kamal app exec 'bin/rails db:migrate'   # rodar migrations
kamal app exec 'bin/rails db:seed'      # rodar seeds
kamal redeploy                          # redeploy sem rebuild (mais rápido)
kamal rollback                          # volta para a versão anterior
kamal app details                       # status dos containers
```

### Verificando o deploy

```bash
kamal app details                    # deve mostrar containers rodando
curl https://seudominio.com.br/up    # endpoint de health check do Rails
```

---

### Alternativa: Deploy manual com Docker + Nginx

Se preferir não usar o Kamal, suba diretamente no servidor:

**1. Build e run da imagem:**

```bash
docker build -t videira-dental .
docker run -d \
  -p 3000:3000 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL=postgresql://usuario:senha@localhost:5432/videira_dental_production \
  -e REDIS_URL=redis://localhost:6379/0 \
  -e SECRET_KEY_BASE=$(bin/rails secret) \
  -e GOOGLE_CLIENT_ID=... \
  -e GOOGLE_CLIENT_SECRET=... \
  -e MERCADOPAGO_ACCESS_TOKEN=... \
  -e MERCADOPAGO_WEBHOOK_SECRET=... \
  --name videira-dental \
  videira-dental
```

**2. Configurar Nginx como proxy reverso:**

```nginx
server {
    server_name seudominio.com.br;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**3. Obter SSL com Certbot:**

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d seudominio.com.br
```

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

## Troubleshooting

### `PG::ConnectionBad: FATAL: role "usuario" does not exist`

Seu usuário do sistema não tem permissão no PostgreSQL. Execute:

```bash
sudo -u postgres createuser $USER --superuser
```

### `Redis::CannotConnectError: Error connecting to Redis`

O Redis não está rodando. Inicie-o:

```bash
redis-server
# ou como serviço:
sudo systemctl start redis
```

### `ActionController::InvalidAuthenticityToken` no webhook

O webhook do MercadoPago não envia token CSRF. Isso já está tratado no `WebhooksController` com `protect_from_forgery with: :null_session`. Se aparecer esse erro, verifique se está acessando a rota correta (`POST /webhooks/mercadopago`).

### Webhook não chega em desenvolvimento

O MercadoPago precisa de uma URL HTTPS pública. Use ngrok:

```bash
ngrok http 3000
```

Atualize a URL no painel do MercadoPago cada vez que o ngrok reiniciar (a URL muda a cada sessão na versão gratuita).

### `HMAC inválido` — webhook retorna 401

O `MERCADOPAGO_WEBHOOK_SECRET` no `.env` não bate com o configurado no painel do MP. Verifique e copie novamente. Em desenvolvimento com o secret começando com `mock`, a validação é ignorada automaticamente.

### Login com Google redireciona para erro

- Verifique se `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` estão corretos no `.env`
- Confirme que `http://localhost:3000/auth/google_oauth2/callback` está na lista de **Authorized redirect URIs** no Google Cloud Console
- Reinicie o servidor após alterar o `.env`

### Assets não compilam / Tailwind não atualiza

Certifique-se de subir o servidor com `bin/dev` (não `bin/rails server`). O `bin/dev` inicia o compilador do Tailwind em paralelo.

### `bin/rails db:seed` falha com e-mail duplicado

O seed já foi rodado antes. Limpe o banco e rode novamente:

```bash
bin/rails db:drop db:create db:migrate db:seed
```

---

## Variáveis de ambiente completas

Veja o arquivo [`.env.example`](.env.example) para a lista completa com descrições.
