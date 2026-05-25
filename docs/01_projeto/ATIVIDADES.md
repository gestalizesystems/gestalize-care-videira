# Atividades Pendentes — Videira Dental

> Revise, ajuste prioridades e remova o que não se aplica antes de iniciar a implementação.

---

## Legenda de prioridade

- 🔴 **Crítico** — app quebrado ou inutilizável sem isso
- 🟡 **Importante** — feature incompleta, mas o app roda
- 🟢 **Melhoria** — qualidade, UX ou cobertura de testes

---

## 1. Views faltando (app quebra ao navegar)

> ✅ Itens 1.1, 1.2, 1.3 já foram implementados.
> ✂️ Item 1.4 (`/servicos`) foi removido — o modelo do app é aluguel de sala (turnos),
> não navegação por especialidade. Se voltar a ser necessário, recriar a rota
> `scheduling/servicos`, o controller e as views.

---

## 2. Sistema de créditos (substitui reembolso MercadoPago)

Quando uma reserva é cancelada após o pagamento ter sido confirmado, o dentista deve receber um crédito em conta (sem estorno no gateway). O crédito pode ser usado para abater o valor de futuras reservas.

### 2.1 🔴 Modelo `Credit`
Novo modelo para registrar créditos por usuário.

Campos sugeridos:
- `user` (belongs_to)
- `clinic` (belongs_to)
- `amount_cents` (integer, > 0)
- `reason` (string — ex: "Cancelamento reserva #abc")
- `source_booking_group` (belongs_to BookingGroup, optional)
- `expires_at` (datetime, optional — crédito com validade?)
- `used_at` (datetime, nullable — quando foi consumido)

### 2.2 🔴 Serviço `CreditIssuer`
Chamado pelo `BookingCanceller` quando o grupo já estava `confirmed` (pagamento já feito).

Responsabilidades:
- Verificar se o pagamento estava em status `paid`
- Criar o registro em `Credit` com `amount_cents = payment.amount_cents`
- Registrar o motivo e a origem

### 2.3 🟡 Aplicar crédito no checkout
No `BookingGroupCreator`, antes de gerar o Pix, verificar se o usuário tem créditos disponíveis e abater do total.

Fluxo sugerido:
1. Calcular total com desconto (`DiscountCalculator`)
2. Buscar créditos disponíveis do usuário para aquela clínica (não expirados, não usados)
3. Abater: `valor_pix = max(0, total - creditos_disponiveis)`
4. Marcar créditos usados (`used_at = Time.current`)
5. Se `valor_pix == 0`, criar o `BookingGroup` direto como `confirmed` sem gerar Pix

### 2.4 🟡 Exibição de créditos disponíveis
- Tela de perfil do dentista deve mostrar saldo de créditos disponíveis
- Tela de confirmação de reserva (`scheduling/bookings/new`) deve informar se há créditos que serão aplicados

### 2.5 🟢 Admin — Visualização de créditos
Painel admin com listagem de créditos emitidos por clínica (quem recebeu, valor, origem, status).

---

## 3. Emails transacionais

`ApplicationMailer` existe mas nenhum mailer foi implementado. O `from` ainda está como `from@example.com`.

### 3.1 🟡 `BookingMailer`
- `confirmation(booking_group)` — enviado ao dentista quando o pagamento é confirmado
- `cancellation(booking_group)` — enviado ao dentista quando a reserva é cancelada
- `credit_issued(user, credit)` — enviado ao dentista informando o crédito gerado

### 3.2 🟡 Integrar mailers nos serviços
- `PaymentConfirmer` → `BookingMailer.confirmation(...).deliver_later`
- `BookingCanceller` → `BookingMailer.cancellation(...).deliver_later`
- `CreditIssuer` → `BookingMailer.credit_issued(...).deliver_later`

### 3.3 🟢 Configuração de SMTP
`config/environments/production.rb` deve configurar SMTP (ex: Postmark, SendGrid, Amazon SES).
Variáveis de ambiente a definir: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAILER_FROM`.

---

## 4. Multi-clínica

Atualmente `Clinic.first` está hardcoded em dois lugares:

- `app/controllers/pages_controller.rb:8` — `Clinic.first`
- `app/controllers/scheduling/servicos_controller.rb:5` — `Clinic.first`

### 4.1 🟢 Subdomain ou slug por clínica
Definir como a clínica é identificada na URL — opções:
- **Subdomínio**: `videira.app.com.br` → resolve a clínica pelo subdomínio
- **Slug na URL**: `/c/videira-dental/servicos`
- **Clínica única por deploy** (atual, só precisa remover o `first` e usar uma constante configurável via ENV)

> Decidir a abordagem antes de implementar.

---

## 5. Cobertura de testes

### 5.1 🟡 Request specs — admin
Faltam specs para os controllers admin:
- `spec/requests/admin/services_spec.rb`
- `spec/requests/admin/availabilities_spec.rb`
- `spec/requests/admin/bookings_spec.rb`
- `spec/requests/admin/discount_rules_spec.rb`
- `spec/requests/admin/payments_spec.rb`
- `spec/requests/admin/clinics_spec.rb`

### 5.2 🟡 Request specs — fluxo de agendamento
- `spec/requests/scheduling/servicos_spec.rb`
- `spec/requests/scheduling/carts_spec.rb`
- `spec/requests/scheduling/bookings_spec.rb` (new/create/cancel)

### 5.3 🟢 Model spec — `Credit`
A ser criado junto com o modelo (item 2.1).

### 5.4 🟢 Service spec — `CreditIssuer`
A ser criado junto com o serviço (item 2.2).

---

## 6. Melhorias pontuais

### 6.1 🟢 Seed — mais dados de exemplo
O seed atual cria apenas horários de "Consulta". Adicionar horários para os outros 3 serviços com datas variadas para facilitar testes manuais.

### 6.2 🟢 Dashboard — gráfico de receita mensal
O dashboard mostra 3 cards estáticos. Um gráfico de barras simples (últimos 6 meses) daria visibilidade de sazonalidade. Pode usar Chart.js via CDN ou Stimulus.

### 6.3 🟢 Paginação nas listas do admin — consistência
`Admin::BookingsController` e `Admin::PaymentsController` usam `pagy`, mas `Admin::UsersController` tem `limit(10)` no show do usuário (não na listagem principal). Verificar consistência.

### 6.4 🟢 Avatar no perfil
`User` já tem `has_one_attached :avatar` e `avatar_url`. A view de perfil (item 1.3) deve permitir upload e exibição.

---

## 7. Achados da análise de 2026-05-25

> Itens identificados durante a varredura de código morto e revisão geral.

### 7.1 🟡 `Booking#dentist` usa coluna `patient_id`
`app/models/booking.rb` declara `belongs_to :dentist, class_name: "User", foreign_key: :patient_id`.
Mesma coisa em `BookingGroup`. A coluna foi herdada do modelo antigo (paciente) e renomear
exige migration + ajustes em policies/services.

- **Por quê:** modelo era para pacientes; virou aluguel de sala. Manter o nome `patient_id`
  causa confusão para qualquer pessoa lendo o código pela primeira vez.
- **Como aplicar:** criar migration `rename_column :bookings, :patient_id, :dentist_id`
  (idem em `booking_groups`), ajustar foreign keys, índices, `User#has_many` e policies.

### 7.2 🟢 Múltiplos `Clinic.first` ainda hardcoded
- `app/controllers/pages_controller.rb` linha 11
- (havia também em `scheduling/servicos_controller.rb`, agora removido)

Item 4.1 cobre a decisão arquitetural (subdomínio vs slug vs deploy único).

### 7.3 🟢 Locale `booking.status.*` provavelmente sem uso
`config/locales/pt-BR.yml` define `booking.status.{pending,confirmed,cancelled}` mas
as views só usam `booking_group.status.*`. Verificar e remover se realmente não há uso.

### 7.4 🟢 CSS — variáveis e classes possivelmente sem uso
`app/assets/tailwind/application.css` define `--color-vdc-pix`, `--font-vdc`,
`--radius-vdc` que não aparecem em nenhum `text-vdc-pix`, `font-vdc`, etc.
Também há classes utilitárias (`badge-danger`, `badge-neutral`, `btn-sm-outline`) com uso
limitado — auditar antes de remover.

### 7.5 🟡 Layouts de mailer existem mas nenhum mailer foi implementado
`app/mailers/application_mailer.rb` tem `from "from@example.com"` (placeholder) e
`app/views/layouts/mailer.{html,text}.erb` estão prontos. Coberto pelos itens 3.1–3.3.

### 7.6 🟢 `ApplicationJob` tem só comentários
`app/jobs/application_job.rb` contém apenas placeholders comentados (`retry_on`,
`discard_on`). Decidir política global de retry para jobs (relevante quando
`BookingMailer` e jobs de crédito forem adicionados).

### 7.7 🟢 Dependências do Gemfile a revisar
- `omniauth-rails_csrf_protection` — só faz sentido com OmniAuth. Confirmar que continua.
- `selenium-webdriver` + `capybara` — não há specs de sistema (`spec/system` não existe).
  Remover se não houver plano de adicionar testes E2E, ou criar pelo menos um spec base.

---

## Ordem de implementação sugerida

1. **1.1 + 1.2 + 1.3** — Views faltando (desbloqueiam navegação) ✅ concluído
2. **2.1 + 2.2** — Modelo e serviço de crédito (núcleo da feature)
3. **2.3 + 2.4** — Aplicar crédito no checkout + exibição no perfil
4. **3.1 + 3.2** — Mailers + integração nos serviços
5. **5.1 + 5.2** — Cobertura de testes request specs
6. **7.1** — Renomear `patient_id` para `dentist_id` (DX/clareza)
7. Demais melhorias conforme prioridade
