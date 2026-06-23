# Atividades — Videira Dental

> Documento histórico. As atividades originais foram implementadas em 2026-05-25.
> Pendências remanescentes (configurações externas) estão na seção final.

---

## Legenda de prioridade

- 🔴 **Crítico** — app quebrado ou inutilizável sem isso
- 🟡 **Importante** — feature incompleta, mas o app roda
- 🟢 **Melhoria** — qualidade, UX ou cobertura de testes

---

## ✅ Concluído

### Views faltando (§1)
- Admin Serviços, Clínica, Perfil — implementados.
- `/servicos` público — removido (modelo do app é aluguel de sala, não navegação por especialidade).

### Sistema de créditos (§2)
- `Credit` model com `user`, `clinic`, `source_booking_group`, `used_on_booking_group`, `amount_cents`, `reason`, `used_at`. Sem `expires_at` por decisão de produto.
- `CreditIssuer` service emite crédito quando grupo confirmado é cancelado.
- `BookingGroupCreator` aplica créditos disponíveis no checkout (FIFO) e cria pagamento `credit` quando total fica zero.
- Perfil do dentista mostra saldo de crédito; tela `confirmar reserva` mostra "Crédito aplicado" e "Total a pagar via Pix" (ou "Confirmar reserva" se cobre 100%).
- Admin: `/admin/credits` com filtros Todos / Disponíveis / Usados.

### Mailers (§3)
- `BookingMailer#confirmation`, `#cancellation`, `#credit_issued` com templates HTML+text.
- Integração: `PaymentConfirmer` → confirmation; `BookingCanceller` → cancellation + credit_issued.
- `ApplicationMailer` agora lê `MAILER_FROM` do ENV (default `no-reply@videiradental.com.br`).
- SMTP configurado em `config/environments/production.rb` via `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`.

### Multi-clínica (§4)
- `Current.clinic` (CurrentAttributes) resolve via `ENV["CLINIC_ID"]` com fallback para `Clinic.first`.
- `pages_controller.rb` usa `Current.clinic`. Hardcode removido.

### Cobertura de testes (§5)
- Request specs: `admin/{services,availabilities,bookings,discount_rules,clinics,credits,payments}`, `scheduling/{carts,bookings}`.
- Model spec: `credit_spec.rb` (associations, validations, scopes, balance_for).
- Service spec: `credit_issuer_spec.rb` (payment paid / pending / nil / no group).
- System specs: `booking_flow_spec.rb`, `admin_dashboard_spec.rb` com Capybara.
- `spec/support/capybara.rb` configurado com `driven_by :rack_test`. **Nota (auditoria 2026-06-10):** não há `selenium-webdriver` no Gemfile — specs `js: true` não são suportados hoje (pendência na Fase 1 do ROADMAP).

### Melhorias (§6)
- Seed agora cria 30 dias de turnos + um crédito demo de R$ 50,00 para a dentista.
- Dashboard tem gráfico SVG inline com receita dos últimos 6 meses.
- Paginação Pagy auditada — todas as listagens admin já usam `pagy`.
- Avatar no perfil já implementado (upload em `users/profiles/edit.html.erb`).

### Achados internos (§7)
- `7.1` Coluna `patient_id` renomeada para `dentist_id` em `bookings` e `booking_groups`. Modelos, policies e specs atualizados.
- `7.2` `Clinic.first` substituído por `Current.clinic`.
- `7.3` Locale `booking.status.*` (sem uso) removido de `pt-BR.yml`.
- `7.4` CSS — variáveis sem uso removidas (`--color-vdc-pix`, `--font-vdc`, `--radius-vdc`, `--pix-color`); classes mortas (`badge-danger`, `badge-neutral`) removidas.
- `7.5` `ApplicationMailer` agora usa `MAILER_FROM` do ENV.
- `7.6` `ApplicationJob` ganhou `retry_on ActiveRecord::Deadlocked` (3 tentativas) e `discard_on ActiveJob::DeserializationError`.
- `7.7` Capybara agora tem uso real (system specs com rack_test).

---

## 2026-06 — Preparação para produção (go-live)

Sistema publicado em produção (Railway + domínio `www.videiraclinic.com.br`).
Guia de infraestrutura: [[DEPLOY_PRODUCAO]].

### Deploy & infraestrutura
- `8.1` Deploy no **Railway** via `railway.toml` + `bin/railway-start.sh` (Puma + Sidekiq + migrations no mesmo serviço).
- `8.2` E-mail migrado de **SMTP → Resend** (Railway bloqueia portas SMTP). `delivery_method = :resend`.
- `8.3` Domínio próprio `www.videiraclinic.com.br` (registro.br) + HTTPS automático.

### Autenticação & conta
- `8.4` **Confirmação de conta por e-mail** (`:confirmable`, estrito) — login Google e seed auto-confirmados; migração confirma usuários já existentes.
- `8.5` **Login/Cadastro com Google** (botão com `button_to` por causa do CSRF do omniauth).
- `8.6` **Completar cadastro** após login Google: gate redireciona perfil incompleto para `/completar-cadastro` (CPF, CRO, telefone, termos).
- `8.7` Link **"Esqueci minha senha"** na tela de login.
- `8.8` **Aceite dos termos obrigatório** no cadastro (validação `acceptance` no servidor; Google/seed isentos).

### Pagamentos
- `8.9` Expiração do Pix mais precisa — `ExpirePaymentsJob` roda a cada 1 min (antes 5).
- `8.10` **Pagamento Pix tardio vira crédito**: webhook para reserva já expirada gera crédito (idempotente) em vez de ignorar. Ver [[INFINITEPAY]].

### Admin & dados
- `8.11` Listagem de reservas mostra apenas **pagas/confirmadas** (esconde expiradas/pendentes/canceladas por padrão).
- `8.12` Exclusão de cliente refinada: permite excluir quem **não tem pagamento/crédito** (reservas abandonadas saem junto); bloqueia só histórico financeiro real.

### Conteúdo, e-mails & UI
- `8.13` Renomeação de exibição **"Videira Dental" → "Videira Clinic"** em todo o sistema.
- `8.14` E-mails do Devise **traduzidos para pt-BR** + identidade Videira Clinic (`devise.pt-BR.yml`).
- `8.15` Página **/termos** linkada em login, cadastro e reserva.
- `8.16` **Open Graph** (preview do link no WhatsApp/redes) com logo, título e descrição.
- `8.17` **Avatar removido** (sem upload de foto; listas mostram iniciais).
- `8.18` Ajustes de alinhamento de títulos com ícones (admin e termos).

---

## Pendências (apenas configuração / decisões externas)

### ✅ SMTP em produção — RESOLVIDO (Resend)
Resolvido via **Resend** (API HTTP), porque o Railway bloqueia portas SMTP de saída.
Variáveis: `RESEND_API_KEY` + `MAILER_FROM` (domínio `videiraclinic.com.br` verificado). Ver [[DEPLOY_PRODUCAO]].

### 🟡 Definir `CLINIC_ID` em produção
Quando houver mais de uma clínica no banco, definir `ENV["CLINIC_ID"]` no deploy para evitar `Clinic.first`.

### 🟢 Eventual evolução multi-clínica para multi-tenant
Se a clínica deixar de ser única por deploy, evoluir `Current.clinic` para resolver por subdomínio ou slug. Cobre o tema discutido em §4.1.

### 🟢 Reembolso parcial em grupos com cancelamento parcial
Hoje o crédito só é emitido quando o grupo INTEIRO é cancelado. Se o dentista cancela 1 de 3 reservas de um grupo pago, ele perde aquele slot sem crédito. Avaliar se vale emitir crédito proporcional (`booking.price_cents * total_cents / subtotal_cents`).

### 🟢 Crédito com validade
Decidiu-se não ter validade. Se mudar, adicionar coluna `expires_at` + filtro em `Credit.available`.
