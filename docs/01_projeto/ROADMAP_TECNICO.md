# Videira Dental Clinic — ROADMAP_TECNICO.md

> ⚠️ **ARQUIVADO (2026-06-10).** Este roadmap guiou a construção do MVP e foi **concluído**.
> Partes dele ficaram históricas: o gateway virou **InfinitePay** (não MercadoPago), não existe model `Room`,
> money é em centavos e enums são string — ver `../02_arquitetura/ARQUITETURA.md` para o estado atual.
> O roadmap ativo agora é o **`ROADMAP.md` (De Júnior a Tech Senior)**.

> Roadmap técnico original, em ordem de implementação.
> Cada tarefa tem: justificativa de ordem, dependências, complexidade, prompt pronto para IA.
> Última atualização: 2026-05-09

---

## Como ler este documento

Cada tarefa segue o formato:

```
### N.M Título — Complexidade: B/M/A
**Depende de:** lista de tarefas anteriores
**Por que agora:** justificativa da ordem
**Entregável:** o que existe ao fim
**Prompt para IA:** prompt copiado e colado, sem edição

[blocos de código quando relevante]
```

**Complexidade:**
- **B (Baixa):** 30 min – 1h. Configuração, migration simples, view padrão.
- **M (Média):** 1h – 3h. Service novo, fluxo cross-model, integração externa simples.
- **A (Alta):** 3h+. Integração com terceiro real (MercadoPago), concorrência, webhook.

**Estimativa total:** 26-34 horas de implementação.

---

## FASE 0 — Setup local (~1.5h)

### 0.1 Pré-requisitos do sistema — B
**Depende de:** nada
**Por que agora:** sem isto nada roda
**Entregável:** Ruby 3.3+, Rails 7.2, Postgres, Redis, Node 18+ instalados e respondendo

```bash
ruby -v && rails -v && psql --version && redis-cli ping && node -v
```

### 0.2 `rails new videira_dental` — B
**Depende de:** 0.1
**Por que agora:** primeira pedra
**Entregável:** projeto Rails vazio com Postgres + Tailwind + Hotwire

```bash
rails new videira_dental \
  --database=postgresql \
  --css=tailwind \
  --skip-jbuilder \
  -T
cd videira_dental
```

> **Mudança vs ROADMAP original:** removida flag `--skip-test`. Vai entrar RSpec depois (vide tarefa 1.6); manter o default minitest gerado **não atrapalha** e fornece scaffolding de `test/` que ignoramos.

### 0.3 Habilitar UUID + timezone — B
**Depende de:** 0.2
**Por que agora:** TODA migration precisa do UUID default; mudar depois quebra todas as FKs já criadas.
**Entregável:** `application.rb` configurado, primeira migration `EnablePgcrypto` rodada

**Prompt para IA:**
```
No projeto Videira Dental Clinic (Rails 7.2 fullstack), edite config/application.rb para:
1. Adicionar config.time_zone = 'America/Sao_Paulo'
2. Adicionar config.i18n.default_locale = :"pt-BR"
3. Configurar UUID como primary key default via config.generators
Em seguida, gere a migration EnablePgcrypto que habilita a extensão pgcrypto no Postgres,
e rode db:create + db:migrate. Confirme que rails db:migrate:status mostra a migration aplicada.
```

### 0.4 Adicionar gems — B
**Depende de:** 0.3
**Por que agora:** instalar tudo de uma vez evita reboots de servidor depois
**Entregável:** Gemfile com todas as gems + `bundle install` ok

```ruby
# Gemfile (adicionar)
gem 'devise'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'pundit'
gem 'mercadopago'
gem 'sidekiq'
gem 'sidekiq-cron'              # job recorrente de expiração
gem 'redis'
gem 'pagy'
gem 'paper_trail'
gem 'image_processing'          # ActiveStorage variants

group :development, :test do
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end
```

### 0.5 Variáveis de ambiente — B
**Depende de:** 0.4
**Por que agora:** o resto vai precisar; melhor ter agora.
**Entregável:** `.env`, `.env.example` e `.gitignore` corretos

Conteúdo do `.env.example` está em **ARQUITETURA.md §12**. Confirmar que `.env` está em `.gitignore` (Rails 7 já põe).

---

## FASE 1 — Banco de dados, models e seeds (~5h)

### 1.1 Rodar todas as migrations — M
**Depende de:** 0.3
**Por que agora:** sem schema, models são inúteis.
**Entregável:** todas as 9+ tabelas criadas com índices, FKs e check constraints conforme **BANCO_DE_DADOS.md §3**

**Prompt para IA:**
```
Use o documento BANCO_DE_DADOS.md como fonte da verdade. Para cada migration listada
em "§3 Migrations (ordem de execução)", gere o arquivo via `rails g migration <Nome>`,
substitua o conteúdo pelo bloco exato do documento (incluindo check constraints e índices)
e rode `rails db:migrate` após cada uma. Confirme que `rails db:schema:dump` reflete
todas as tabelas e índices documentados. NÃO altere nada do que está no documento.
```

### 1.2 ActiveStorage + PaperTrail — B
**Depende de:** 1.1
**Por que agora:** dependências dos models.
**Entregável:** tabelas `active_storage_*` e `versions` criadas com UUID

```bash
rails active_storage:install && rails db:migrate
rails generate paper_trail:install --with-changes
# editar a migration de versions para usar UUID conforme BANCO_DE_DADOS.md §3.11
rails db:migrate
```

### 1.3 Models base — M
**Depende de:** 1.2
**Por que agora:** controllers/services dependem dos models.
**Entregável:** 8 models (Clinic, User, Room, Availability, DiscountRule, BookingGroup, Booking, Payment) com associations, validações, enums, scopes, has_paper_trail e métodos de transição (`confirm!`, `expire!`, `cancel!`, etc.) conforme `codigo/models/`.

> **Refinamentos a aplicar nos arquivos de `codigo/models/`:**
>
> 1. **`Availability#cancellable?`** — usar parsing seguro:
>    ```ruby
>    def cancellable?
>      lead = ENV.fetch('CANCELLATION_LEAD_HOURS', 48).to_i.hours
>      slot_at = Time.zone.local(date.year, date.month, date.day, starts_at.hour, starts_at.min)
>      slot_at > lead.from_now
>    end
>    ```
>    Substitui o `Time.zone.parse("#{date} #{starts_at}")` que é frágil quando `starts_at` é Time.
>
> 2. **`User`** — remover métodos redundantes `def owner? = role == "owner"`. O enum já gera `owner?` e `dentist?`.
>
> 3. **`User#from_omniauth`** — adicionar guard:
>    ```ruby
>    return User.new.tap { |u| u.errors.add(:email, "obrigatório do Google") } if auth.info.email.blank?
>    ```
>
> 4. **`DiscountRule`** — adicionar `validates :min_slots, uniqueness: { scope: :clinic_id }`.
>
> 5. **`BookingGroup#expire!`** — adicionar guard `return unless pending?` no início.
>
> 6. **`Payment`** com `has_paper_trail only: %i[status amount paid_at expires_at]`.

**Prompt para IA:**
```
Crie os 8 models do projeto Videira Dental Clinic em app/models/, usando os arquivos
em codigo/models/ como base, MAS aplicando as 6 correções listadas em ROADMAP_TECNICO.md
seção 1.3. Para cada model:
1. Manter has_paper_trail (com ignore: para campos voláteis em User e Payment)
2. Aplicar as correções específicas (Availability#cancellable?, User redundância, etc.)
3. Garantir que enums seguem a ordem documentada
4. Adicionar comentário curto somente quando o motivo não for óbvio

Após criar, rode `rails console` e valide:
- Clinic.create!(name: "Teste", slug: "teste", owner_email: "x@y.com")
- A clinic criada tem id UUID
- DiscountRule.new(min_slots: 1).valid? === false (rejeita por check constraint)
```

### 1.4 Seeds — B
**Depende de:** 1.3
**Por que agora:** sem seeds, não há como testar manualmente.
**Entregável:** `db/seeds.rb` conforme **BANCO_DE_DADOS.md §7**, rodado com sucesso.

```bash
rails db:seed
# valida: 1 Clinic, 1 owner, 1 Room, 3 DiscountRules, ~117 Availabilities
```

### 1.5 Inicializadores — B
**Depende de:** 1.3
**Por que agora:** Devise/Pundit/PaperTrail/Sidekiq dependem.
**Entregável:** todos os initializers configurados

```bash
rails g devise:install
rails g pundit:install
# config/initializers/paper_trail.rb conforme MODULOS.md §5.4
# config/initializers/sidekiq.rb com Redis URL via ENV
# config/initializers/mercadopago.rb com sanity check de ENV
```

### 1.6 RSpec — B
**Depende de:** 1.4
**Por que agora:** quanto antes os testes existirem, mais cedo cobrem fluxos críticos.
**Entregável:** RSpec instalado, FactoryBot configurado, 1 spec de smoke rodando

```bash
rails g rspec:install
mkdir -p spec/factories spec/models spec/services spec/system
echo "Rails.application.eager_load!" >> spec/spec_helper.rb
```

**Prompt para IA:**
```
No projeto Rails Videira Dental Clinic, configure RSpec + FactoryBot:
1. Adicione FactoryBot::Syntax::Methods em spec/rails_helper.rb
2. Crie factories básicas em spec/factories/ para todos os 8 models
3. Crie spec/models/availability_spec.rb com 3 testes:
   - rejeita ends_at <= starts_at
   - rejeita price <= 0
   - cancellable? retorna false quando faltam menos de 48h
4. Rode `bundle exec rspec` e confirme tudo verde
Use traits em factories para variantes (ex: :booked, :owner, :dentist, :paid).
```

---

## FASE 2 — Autenticação (~3h)

### 2.1 Devise: instalação + customização — M
**Depende de:** 1.5
**Por que agora:** sem auth, nem dentista nem owner conseguem entrar
**Entregável:** Devise gera User table (já feito em 1.1 via DeviseCreateUsers); rotas configuradas; views customizadas com Tailwind

**Prompt para IA:**
```
Configure Devise para o projeto Videira Dental Clinic:
1. Em config/initializers/devise.rb, garanta os módulos:
   :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :omniauthable
2. Configure path_names: { sign_in: 'login', sign_out: 'logout', sign_up: 'cadastro' }
3. Crie Users::RegistrationsController herdando de Devise::RegistrationsController,
   permitindo os campos extras: name, phone, cro_number, specialty, birth_date, terms_accepted
4. Em ApplicationController, adicione before_action :configure_permitted_parameters
   if devise_controller, com strong params permitindo os campos acima em :sign_up e :account_update
5. Customize app/views/devise/sessions/new.html.erb e registrations/new.html.erb seguindo
   o DESIGN_SYSTEM.md (cores #5D4037, fonte Prompt, layout max-w-md)
6. Em devise/registrations/new.html.erb, adicione tabs "Entrar / Criar conta" linkando para login
```

### 2.2 Google OAuth — M
**Depende de:** 2.1
**Por que agora:** opção do botão "Entrar com Google" estava no Figma desde o login
**Entregável:** dentista pode entrar via Google e ser criada/conectada no banco

**Prompt para IA:**
```
Configure Google OAuth para o projeto Videira Dental Clinic:
1. Em config/initializers/devise.rb, adicione:
   config.omniauth :google_oauth2, ENV.fetch('GOOGLE_CLIENT_ID'), ENV.fetch('GOOGLE_CLIENT_SECRET'),
     scope: 'email, profile'
2. Crie app/controllers/users/omniauth_callbacks_controller.rb com action google_oauth2:
   - obter clinic = Clinic.first (MVP single-tenant)
   - chamar User.from_omniauth(request.env["omniauth.auth"], clinic)
   - se persisted: sign_in_and_redirect; senão: redirect para /cadastro com erros
   - implementar action failure que redireciona para / com flash alert
3. Em app/models/user.rb, implemente self.from_omniauth(auth, clinic) conforme codigo/models/user.rb
   COM A CORREÇÃO: se auth.info.email.blank?, retornar User.new com erro (não persistir)
4. Adicione rota em config/routes.rb: devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
5. Adicione botão "Entrar com Google" nas views de Login e Cadastro
```

### 2.3 Pundit policies — M
**Depende de:** 2.2
**Por que agora:** Pundit precisa rodar em todo controller; melhor configurar antes dos controllers
**Entregável:** todas as 7 policies criadas conforme `codigo/policies/all_policies.rb`, separadas em arquivos individuais

**Prompt para IA:**
```
Crie as policies do projeto Videira Dental Clinic em app/policies/, dividindo o conteúdo
de codigo/policies/all_policies.rb em arquivos separados:
- application_policy.rb
- availability_policy.rb
- booking_policy.rb
- booking_group_policy.rb
- payment_policy.rb
- discount_rule_policy.rb
- user_policy.rb

Para cada Scope, garanta que filtra por user.clinic. Adicione testes em spec/policies/ para:
- AvailabilityPolicy: dentist NÃO pode create/update/destroy; owner pode (exceto destroy se booked)
- BookingGroupPolicy: dentist só vê os próprios; owner vê todos da clinic
- DiscountRulePolicy: somente owner

Em ApplicationController, garanta:
include Pundit::Authorization
after_action :verify_authorized,    except: :index, unless: :devise_controller?
after_action :verify_policy_scoped, only:   :index, unless: :devise_controller?
```

---

## FASE 3 — Frontend base (~2h)

### 3.1 Design system: cores + fonte — B
**Depende de:** 0.2
**Por que agora:** toda view daqui pra frente usa
**Entregável:** `application.tailwind.css` com `@import` do Prompt + CSS vars; `tailwind.config.js` com cores nomeadas

**Prompt para IA:**
```
No projeto Videira Dental Clinic:
1. Edite app/assets/stylesheets/application.tailwind.css e adicione no topo:
   - @import url do Google Fonts Prompt (300-700)
   - bloco :root com TODAS as CSS variables listadas em DESIGN_SYSTEM.md §2
   - regra body { font-family: 'Prompt', sans-serif; background: var(--background); color: var(--foreground); }
   - regra mobile @media (max-width: 768px) input/select/textarea { font-size: 16px !important; }
2. Edite tailwind.config.js para adicionar:
   colors: { background: '#fef8e1', primary: '#5D4037', secondary: '#8D6E63',
             accent: '#C9B8A8', foreground: '#3E2723', pix: '#32BCAD',
             success: '#388E3C', destructive: '#d4183d' }
   fontFamily: { sans: ['Prompt', 'sans-serif'] }
   borderRadius: { DEFAULT: '0.625rem', '2xl': '1rem', '3xl': '1.5rem' }
3. Rode `bin/dev` e abra localhost:3000 — confirme fundo creme, fonte Prompt
```

### 3.2 Layouts e partials compartilhados — M
**Depende de:** 3.1
**Por que agora:** todas as views dependem; sem layout, nada se vê com identidade
**Entregável:** `application.html.erb`, `admin.html.erb` e os 4 partials base (`_avatar`, `_back_button`, `_flash`, `_logo`)

**Prompt para IA:**
```
Crie os layouts e partials compartilhados do Videira Dental Clinic:

1. app/views/layouts/application.html.erb:
   - <html lang="pt-BR">
   - background creme via Tailwind class bg-background
   - container max-w-md mx-auto px-4 py-6
   - <%= render 'shared/flash' %> sempre no topo
   - turbo_frame_tag "cart" sempre presente para persistir carrinho
   - <%= yield %>

2. app/views/layouts/admin.html.erb (conforme DESIGN_SYSTEM.md §5):
   - mesmo wrapper visual
   - header com logo central e botão logout (button_to method: :delete)
   - grid grid-cols-2 gap-3 com 4 botões (Reservas, Clientes, Disponibilidade, Descontos)
   - <%= yield %>

3. app/views/shared/:
   - _avatar.html.erb (foto OR iniciais OR ícone genérico, com sizes :sm/:md/:lg)
   - _back_button.html.erb (chevron, recebe `path:`)
   - _flash.html.erb (renderiza flash[:notice] e flash[:alert] com cores tema, controller stimulus flash auto-dismiss)
   - _logo.html.erb (logo Videira, link para root_path)

Use SOMENTE classes Tailwind (sem style="..." inline). Cores via classes nomeadas
(bg-primary, text-foreground, etc.) conforme tailwind.config.js.
```

### 3.3 Stimulus controllers base — M
**Depende de:** 3.2
**Por que agora:** payment + cart + week selector dependem
**Entregável:** 7 controllers criados em `app/javascript/controllers/`

**Prompt para IA:**
```
Crie os Stimulus controllers do projeto Videira Dental Clinic em
app/javascript/controllers/. Cada arquivo deve ter export default class extends Controller
e ser registrado automaticamente pelo Stimulus loader.

1. countdown_controller.js — targets: ["display"]; values: { end: Number }
   connect() inicia setInterval, tick() atualiza display "MM:SS", disconnect() limpa interval
2. clipboard_controller.js — values: { text: String }, targets: ["button"]
   copy() faz navigator.clipboard.writeText(this.textValue), troca textContent por "Copiado!" por 2s
3. flash_controller.js — values: { timeout: Number }
   connect() agenda setTimeout(this.dismiss, this.timeoutValue || 3000); dismiss() faz fade-out + remove
4. modal_controller.js — targets: ["overlay"]; open(), close(); ESC fecha
5. phone_mask_controller.js — formata input para "(99) 99999-9999" no input event
6. week_selector_controller.js — controla navegação semanal; usa Turbo.visit para trocar ?date=
7. cart_controller.js — listener para abrir/fechar painel do carrinho

Para cada controller, adicione 1 comentário SOMENTE se o porquê for não-óbvio.
Sem JSDoc.
```

---

## FASE 4 — Funcionalidades da Dentista (~9h)

### 4.1 Home — listagem de slots — M
**Depende de:** 3.2, 1.4
**Por que agora:** primeira tela visível, fluxo principal começa aqui
**Entregável:** `/` mostra slots disponíveis para a data selecionada (ou amanhã)

**Prompt para IA:**
```
No projeto Videira Dental Clinic, implemente a Home conforme DESIGN_SYSTEM.md e CONTEXT.md:

1. HomeController#index (skip auth, after_action skip_authorization):
   - @selected_date = params[:date] ? Date.parse(params[:date]) : Date.tomorrow
   - @clinic = Clinic.first
   - @availabilities = @clinic.room.availabilities.available.for_date(@selected_date)
                                .order(:starts_at) (Availability.none se sem clinic)
   - @cart_ids = session[:cart_ids] || []

2. app/views/home/index.html.erb:
   - render 'shared/logo'
   - se logada: avatar + link para /conta; se anônima: link para /login
   - render 'shared/week_selector' com @selected_date
   - turbo_frame_tag "slots" do (recarrega ao mudar data):
       cada slot: render 'shared/slot_card', slot: av,
                  state: (@cart_ids.include?(av.id) ? :selected : :available)
       se vazio: mensagem "Sem horários disponíveis para esta data"
   - barra inferior fixa quando @cart_ids.any? com link para /reservas/confirmar e total

3. app/views/shared/_slot_card.html.erb conforme DESIGN_SYSTEM.md §4:
   - botão (form post para /carrinho/adicionar ou /carrinho/remover) wrapped em turbo-frame
   - estados visuais: available (creme), selected (accent #C9B8A8), booked (cinza, disabled)

Use Tailwind utility classes nomeadas. Sem style inline.
```

### 4.2 Carrinho — CartController — M
**Depende de:** 4.1
**Por que agora:** Home depende dos endpoints do carrinho
**Entregável:** add/remove/clear funcionando via Turbo Stream

**Prompt para IA:**
```
Implemente CartController para o Videira Dental Clinic conforme MODULOS.md §2:

Routes (já em routes.rb):
  POST   /carrinho/adicionar  → cart#add
  DELETE /carrinho/remover    → cart#remove
  DELETE /carrinho/limpar     → cart#clear

CartController:
- skip_before_action :authenticate_user!
- after_action :skip_authorization
- todas as 3 actions atualizam session[:cart_ids] e respondem com format.turbo_stream renderizando
  turbo_stream.replace "cart" e turbo_stream.replace "slot_<id>" para o slot afetado

app/views/cart/add.turbo_stream.erb e remove.turbo_stream.erb:
  <%= turbo_stream.replace "cart" do %>
    <%= render 'shared/booking_cart', availabilities: @availabilities,
               total: @total, discount_amount: @discount_amount %>
  <% end %>
  <%= turbo_stream.replace "slot_#{params[:availability_id]}" do %>
    <%= render 'shared/slot_card', slot: ..., state: ... %>
  <% end %>

Calcular @total/@discount via DiscountCalculator.call(session[:cart_ids], Clinic.first)
quando @cart_ids.any?.
```

### 4.3 DiscountCalculator service — B
**Depende de:** 1.3
**Por que agora:** carrinho e checkout precisam
**Entregável:** `DiscountCalculator.call(ids, clinic)` retorna hash conforme `codigo/services/discount_calculator.rb`

**Prompt para IA:**
```
Crie app/services/application_service.rb com self.call(...) = new(...).call
Crie app/services/discount_calculator.rb usando o conteúdo de codigo/services/discount_calculator.rb,
mas:
1. Herdando de ApplicationService
2. Recebendo (availability_ids:, clinic:) como kwargs (não posicionais)
3. Retornando OpenStruct (não hash) para permitir result.subtotal vs result[:subtotal]
4. Com test em spec/services/discount_calculator_spec.rb cobrindo:
   - 1 slot → sem desconto
   - 2 slots → regra de 5%
   - 5 slots → regra de 15%
   - 0 slots → subtotal 0, total 0
```

### 4.4 BookingGroupCreator service — A
**Depende de:** 4.3, 4.6 (MercadoPagoService precisa existir antes)
**Por que agora:** core do checkout; precisa de Pix antes de funcionar end-to-end (pode ser implementado em paralelo com 4.6)
**Entregável:** service idempotente e safe para concorrência

**Prompt para IA:**
```
Crie app/services/booking_group_creator.rb no Videira Dental Clinic. Recebe kwargs
(user:, availability_ids:). Comportamento:

class BookingGroupCreator < ApplicationService
  class SlotTaken < StandardError; end
  class CartEmpty < StandardError; end

  def initialize(user:, availability_ids:)
    @user = user; @availability_ids = availability_ids
  end

  def call
    raise CartEmpty if @availability_ids.blank?
    ActiveRecord::Base.transaction do
      availabilities = Availability.where(id: @availability_ids).lock!     # SELECT FOR UPDATE
      raise SlotTaken if availabilities.count != @availability_ids.length
      raise SlotTaken if availabilities.any?(&:booked?)

      calc = DiscountCalculator.call(availability_ids: @availability_ids, clinic: @user.clinic)
      group = BookingGroup.create!(
        user: @user, clinic: @user.clinic,
        discount_rule: calc.discount_rule,
        subtotal: calc.subtotal, discount_percent: calc.discount_percent,
        discount_amount: calc.discount_amount, total: calc.total,
        status: :pending
      )
      availabilities.each do |av|
        Booking.create!(booking_group: group, availability: av, user: @user, status: :pending)
        av.update!(booked: true)
      end

      pix = MercadoPago::PixCreator.call(group)
      raise ActiveRecord::Rollback unless pix[:success]

      Payment.create!(
        booking_group: group, provider: 'mercadopago',
        provider_id: pix[:provider_id], pix_code: pix[:pix_code],
        pix_qr_url: pix[:pix_qr_url], status: :pending,
        amount: group.total,
        expires_at: ENV.fetch('PAYMENT_EXPIRATION_MINUTES', 30).to_i.minutes.from_now
      )
      OpenStruct.new(success?: true, group: group)
    end
  rescue SlotTaken, CartEmpty => e
    OpenStruct.new(success?: false, error: e.message)
  end
end

Inclua spec/services/booking_group_creator_spec.rb cobrindo:
- happy path (cria group + bookings + payment)
- SlotTaken se algum slot já booked
- CartEmpty se ids vazio
- rollback completo se PixCreator falha
```

### 4.5 BookingGroupsController — M
**Depende de:** 4.4
**Entregável:** rotas /reservas/confirmar (new) e POST /reservas (create) e /reservas/:id (show)

**Prompt para IA:**
```
Implemente BookingGroupsController no Videira Dental Clinic:

1. #new (GET /reservas/confirmar):
   - cart_ids = session[:cart_ids] || []
   - redirect_to root_path, alert: "Selecione ao menos um horário." if cart_ids.empty?
   - calc = DiscountCalculator.call(availability_ids: cart_ids, clinic: current_user.clinic)
   - expor @availabilities, @subtotal, @discount_amount, @discount_percent, @total, @discount_rule
   - authorize BookingGroup.new

2. #create (POST /reservas):
   - cart_ids = session[:cart_ids] || []
   - result = BookingGroupCreator.call(user: current_user, availability_ids: cart_ids)
   - se !result.success?: redirect_to root_path, alert: result.error
   - se success: session.delete(:cart_ids); redirect_to payment_path(result.group.payment)
   - authorize BookingGroup.new (antes de chamar o service)

3. #show (GET /reservas/:id):
   - @booking_group = BookingGroup.includes(:bookings, :payment).find(params[:id])
   - authorize @booking_group

4. View booking_groups/new.html.erb conforme DESIGN_SYSTEM.md:
   - back button para /
   - card branco com lista de slots (data, horário, valor unitário)
   - separador
   - linha "Subtotal" (preto), "Desconto -X%" (verde) se aplicável
   - linha "Total" em destaque
   - button_to "Pagar com Pix" → POST /reservas (style: bg-primary)

NÃO duplique a lógica do BookingGroupCreator no controller — o controller só chama o service.
```

### 4.6 MercadoPago: PixCreator + PaymentFinder + WebhookValidator — A
**Depende de:** 0.5 (env vars), 1.3 (Payment model)
**Por que agora:** precisa antes do BookingGroupCreator funcionar end-to-end
**Entregável:** 3 services em `app/services/mercado_pago/`

**Prompt para IA:**
```
Crie os 3 services em app/services/mercado_pago/:

1. pix_creator.rb (refactor de codigo/services/mercado_pago_service.rb):
   class MercadoPago::PixCreator < ApplicationService
     def initialize(booking_group); @group = booking_group; end
     def call
       sdk = Mercadopago::SDK.new(ENV.fetch('MERCADOPAGO_ACCESS_TOKEN'))
       expires_at = ENV.fetch('PAYMENT_EXPIRATION_MINUTES', 30).to_i.minutes.from_now
       response = sdk.preference.create({...mesmos campos do código original...,
         date_of_expiration: expires_at.iso8601,
         external_reference: @group.id })
       if response[:status] == 201
         r = response[:response]
         { success: true,
           provider_id: r["id"].to_s,
           pix_code:    r.dig("point_of_interaction","transaction_data","qr_code"),
           pix_qr_url:  r.dig("point_of_interaction","transaction_data","qr_code_base64"),
           expires_at:  expires_at }
       else
         Rails.logger.error("MercadoPago PixCreator failed: #{response.inspect}")
         { success: false }   # IMPORTANTE: sem fallback "MOCK_PIX_…" em produção
       end
     end
   end

2. payment_finder.rb:
   class MercadoPago::PaymentFinder < ApplicationService
     def initialize(provider_payment_id); @id = provider_payment_id; end
     def call
       sdk = Mercadopago::SDK.new(ENV.fetch('MERCADOPAGO_ACCESS_TOKEN'))
       resp = sdk.payment.get(@id)
       resp[:status] == 200 ? resp[:response] : nil
     end
   end

3. webhook_validator.rb:
   class MercadoPago::WebhookValidator < ApplicationService
     def initialize(request); @request = request; end
     def call
       signature = @request.headers['x-signature']
       request_id = @request.headers['x-request-id']
       data_id = @request.params['data.id'] || JSON.parse(@request.body.read).dig('data','id')
       return false if [signature, request_id, data_id].any?(&:blank?)

       parts = signature.split(',').map { |p| p.split('=', 2) }.to_h.transform_values(&:strip)
       ts = parts['ts']; v1 = parts['v1']
       template = "id:#{data_id};request-id:#{request_id};ts:#{ts};"
       expected = OpenSSL::HMAC.hexdigest('sha256', ENV.fetch('MERCADOPAGO_WEBHOOK_SECRET'), template)
       ActiveSupport::SecurityUtils.secure_compare(expected, v1)
     end
   end

NÃO commite o fallback "MOCK_PIX_<id>" usado no código original — em produção isso confunde
debug. Em sandbox, o próprio MP retorna qr_code válido. Falha = retornar success: false.
```

### 4.7 PaymentConfirmer service — M
**Depende de:** 4.6
**Entregável:** chamado pelo webhook; idempotente; faz broadcast Turbo Stream

**Prompt para IA:**
```
Crie app/services/payment_confirmer.rb:

class PaymentConfirmer < ApplicationService
  def initialize(external_reference:); @ref = external_reference; end
  def call
    group = BookingGroup.includes(:payment).find_by(id: @ref)
    return :missing if group.nil?
    return :already_confirmed if group.confirmed?
    return :already_expired   if group.expired?
    group.confirm!
    Turbo::StreamsChannel.broadcast_replace_to(
      "payment_#{group.payment.id}",
      target:  "payment_status",
      partial: "payments/paid",
      locals:  { payment: group.payment.reload }
    )
    :confirmed
  end
end

Inclua spec/services/payment_confirmer_spec.rb cobrindo:
- :missing quando ref não existe
- :already_confirmed quando group.confirmed
- :confirmed muda status e dispara broadcast (mock)
- chamada dupla é idempotente
```

### 4.8 PaymentsController + tela de pagamento — A
**Depende de:** 4.6, 4.7, 3.3
**Entregável:** `/pagamento/:id` mostra QR + countdown + status com Turbo Stream live

**Prompt para IA:**
```
Implemente o fluxo de pagamento no Videira Dental Clinic:

1. PaymentsController:
   def show
     @payment = Payment.includes(booking_group: %i[bookings user]).find(params[:id])
     authorize @payment
   end

2. app/views/payments/show.html.erb:
   - back_button para /minhas-reservas
   - h1 "Pagamento via Pix"
   - <%= turbo_stream_from "payment_#{@payment.id}" %>
   - <%= turbo_frame_tag "payment_status" do %>
       <%= render "payments/#{@payment.status}", payment: @payment %>
     <% end %>

3. app/views/payments/_pending.html.erb conforme DESIGN_SYSTEM.md §4 _pix_payment:
   - QR como <img src="data:image/png;base64,<%= payment.pix_qr_url %>">
   - Countdown via Stimulus countdown controller
   - Bloco copia/cola via Stimulus clipboard controller
   - Botão "Já paguei? Verificar" (form para uma action que faz reload — fallback se polling não chegar)

4. app/views/payments/_paid.html.erb:
   - check verde grande, "Pagamento confirmado!"
   - resumo das reservas
   - link para /minhas-reservas

5. app/views/payments/_expired.html.erb:
   - mensagem destrutiva, link para /

Garanta que ActionCable está configurado (config/cable.yml redis adapter em prod).
```

### 4.9 WebhooksController + idempotência — A
**Depende de:** 4.7
**Entregável:** webhook validado, processado e respondendo 200

**Prompt para IA:**
```
Implemente WebhooksController no Videira Dental Clinic:

class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  after_action :skip_authorization

  def mercadopago
    body = request.body.read
    request.body.rewind   # permite que validator releia
    return head :unauthorized unless MercadoPago::WebhookValidator.call(request)

    payload = JSON.parse(body)
    return head :ok unless payload['type'] == 'payment'

    mp_data = MercadoPago::PaymentFinder.call(payload.dig('data', 'id'))
    return head :ok if mp_data.nil?
    return head :ok unless mp_data['status'] == 'approved'

    PaymentConfirmer.call(external_reference: mp_data['external_reference'])
    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue => e
    Rails.logger.error("Webhook MP failed: #{e.message}")
    head :ok   # MP retentaria; aceitamos e investigamos via log
  end
end

Crie spec/requests/webhooks_spec.rb cobrindo:
- 401 se assinatura inválida
- 200 e ignora se type != "payment"
- 200 e chama PaymentConfirmer se status == "approved"
- 200 mesmo em erro inesperado (não queremos retentativas infinitas)
```

### 4.10 ExpirePaymentsJob + sidekiq-cron — M
**Depende de:** 1.5, 4.4
**Entregável:** job recorrente a cada 5 min limpando payments expirados

**Prompt para IA:**
```
Implemente o job de expiração:

app/jobs/expire_payments_job.rb:
class ExpirePaymentsJob < ApplicationJob
  queue_as :default
  def perform
    Payment.expiring.includes(:booking_group).find_each do |payment|
      next if payment.booking_group.confirmed?
      payment.booking_group.expire!
      Turbo::StreamsChannel.broadcast_replace_to(
        "payment_#{payment.id}",
        target:  "payment_status",
        partial: "payments/expired",
        locals:  { payment: payment.reload }
      )
      Rails.logger.info("[ExpirePayments] Group #{payment.booking_group_id} expired")
    end
  end
end

config/sidekiq.yml:
:concurrency: 5
:queues:
  - default

config/initializers/sidekiq.rb:
Sidekiq.configure_server do |c|
  c.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end
Sidekiq.configure_client do |c|
  c.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

require 'sidekiq/cron/job'
schedule_file = Rails.root.join('config/sidekiq_schedule.yml')
Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file)) if File.exist?(schedule_file)

config/sidekiq_schedule.yml:
expire_payments:
  cron: "*/5 * * * *"
  class: "ExpirePaymentsJob"
  description: "Expira pagamentos não pagos"

Verifique com: bundle exec sidekiq → checar log a cada 5 min.
```

### 4.11 BookingsController + cancelamento — M
**Depende de:** 4.5
**Entregável:** /minhas-reservas e PATCH /bookings/:id/cancel

**Prompt para IA:**
```
Implemente BookingsController no Videira Dental Clinic:

class BookingsController < ApplicationController
  before_action :set_booking, only: %i[show cancel]

  def index
    @pagy, @booking_groups = pagy(
      policy_scope(BookingGroup).includes(:bookings, :payment).order(created_at: :desc),
      items: 10
    )
    authorize BookingGroup
  end

  def show
    authorize @booking
  end

  def cancel
    authorize @booking, :cancel?
    reason = params[:cancel_reason].to_s.strip
    return redirect_to bookings_path, alert: "Informe o motivo." if reason.blank?
    BookingCanceller.call(booking: @booking, reason: reason)
    redirect_to bookings_path, notice: "Reserva cancelada com sucesso."
  rescue BookingCanceller::TooLate
    redirect_to bookings_path, alert: "Cancelamento exige 48h de antecedência."
  end

  private
  def set_booking = @booking = Booking.find(params[:id])
end

E o service:

class BookingCanceller < ApplicationService
  class TooLate < StandardError; end
  def initialize(booking:, reason:); @booking = booking; @reason = reason; end
  def call
    raise TooLate unless @booking.availability.cancellable?
    ActiveRecord::Base.transaction do
      @booking.update!(status: :cancelled, cancelled_at: Time.current, cancel_reason: @reason)
      @booking.availability.update!(booked: false)
      group = @booking.booking_group
      group.update!(status: :cancelled) if group.bookings.where.not(status: :cancelled).none?
    end
  end
end

View bookings/index.html.erb agrupada por mês (group_by(&:created_at).month):
- card por BookingGroup mostrando: data + valor + status badge
- expand para listar bookings individuais com botão "Cancelar" se elegível

Move a lógica de cancelamento para o service para tirar do model — testabilidade.
```

### 4.12 Conta — UsersController#show / #update — M
**Depende de:** 4.1
**Entregável:** /conta com formulário editável (sem email)

**Prompt para IA:**
```
Implemente UsersController para o perfil da dentista no Videira Dental Clinic:

class UsersController < ApplicationController
  def show
    @user = current_user
    authorize @user
  end

  def update
    @user = current_user
    authorize @user
    if @user.update(user_params)
      redirect_to conta_path, notice: "Dados atualizados com sucesso."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
  def user_params
    params.require(:user).permit(:name, :phone, :specialty, :birth_date, :avatar)
  end
end

View users/show.html.erb:
- back button para /
- avatar grande (size: :lg) com upload (form_with multipart)
- form com fields: name, phone, specialty, birth_date, avatar
- botão "Salvar"
- link "Sair" (button_to destroy_user_session_path, method: :delete)

NOTA: email não está em user_params (consistente com regra: alteração de email exige fluxo Devise próprio).
```

---

## FASE 5 — Painel Admin (~5h)

### 5.1 Admin::BaseController + layout — B
**Depende de:** 2.3, 3.2
**Entregável:** require_owner! ativo, redirect amigável para não-owner

### 5.2 Admin::AvailabilitiesController CRUD — M
**Depende de:** 5.1
**Entregável:** owner cria/edita/deleta slots; bloqueio de delete se booked

**Prompt para IA:**
```
Implemente Admin::AvailabilitiesController CRUD no Videira Dental Clinic, conforme
codigo/controllers/admin_controllers.rb e MODULOS.md §4. Garanta:
1. authorize em todas as actions
2. policy_scope no index (filtro por clinic)
3. destroy bloqueado se booked? (mensagem amigável)
4. params permitidos: date, starts_at, ends_at, price
5. Atribuir room: current_user.clinic.room e created_by: current_user no create

Views (admin/availabilities/):
- index.html.erb: render 'shared/week_selector' + lista de slots do dia + botão "Adicionar"
- new.html.erb e edit.html.erb: form_with model: [:admin, @availability]
- _form.html.erb: campos date/starts_at/ends_at/price com tema VDC

Spec: spec/system/admin_availabilities_spec.rb cobrindo happy path + bloqueio de destroy.
```

### 5.3 Admin::DiscountRulesController CRUD — M
**Depende de:** 5.1
**Entregável:** owner gerencia regras de desconto. **Soft-delete** via toggle `active`.

**Prompt para IA:**
```
Implemente Admin::DiscountRulesController no Videira Dental Clinic. CRÍTICO: como
booking_groups referenciam discount_rule_id, NÃO é seguro hard-delete uma rule já usada.

Implemente como soft-delete via active flag:

def destroy
  authorize @rule
  @rule.update!(active: false)
  redirect_to admin_discount_rules_path, notice: "Regra desativada."
end

Views (admin/discount_rules/):
- index.html.erb: tabela com min_slots, discount_percent, active (badge), ações (editar / ativar-desativar)
- new.html.erb e edit.html.erb: form com min_slots (>= 2), discount_percent (0-100], active

Adicione validação no model: validates :min_slots, uniqueness: { scope: :clinic_id }
(se ainda não foi adicionada na fase 1).
```

### 5.4 Admin::BookingsController — M
**Depende de:** 5.1
**Entregável:** owner vê todas as reservas com filtro por data e edita status

**Prompt para IA:**
```
Implemente Admin::BookingsController conforme codigo/controllers/admin_controllers.rb.
Adicione:
1. Filtro por data (params[:date]) com seletor de semana
2. Filtro por status (params[:status])
3. Paginação via pagy (20 por página)
4. View admin/bookings/show.html.erb com 2 abas:
   - Detalhes (slots, dentista, payment, datas)
   - Histórico (render 'shared/versions_table', versions: @booking_group.versions)
5. Action update permite mudar status manualmente (caso de exceção); toda mudança fica no PaperTrail
```

### 5.5 Admin::UsersController — M
**Depende de:** 5.1
**Entregável:** lista, busca, detalhes com 3 abas (dados / reservas / histórico)

**Prompt para IA:**
```
Implemente Admin::UsersController conforme codigo/controllers/admin_controllers.rb e MODULOS.md §4.

CRÍTICO:
1. admin_user_params NÃO inclui :email (regra de negócio)
2. Inclui: name, phone, cro_number, specialty, birth_date
3. Busca: name ILIKE OR cro_number ILIKE com bind parametrizado (?)

View admin/users/show.html.erb com 3 abas via Stimulus tabs controller (criar se necessário):
- Dados: form_with [:admin, @user] sem campo :email
- Reservas: lista @booking_groups (ordenada por created_at desc)
- Histórico: render 'shared/versions_table', versions: @user.versions

Crie app/views/shared/_versions_table.html.erb genérico que recebe versions:
| Quando (formatado) | Quem (lookup pelo whodunnit) | Evento | Diff |
Para cada version, decode object_changes (jsonb) e renderiza linha por atributo mudado.
```

### 5.6 Helper de PaperTrail diff — B
**Depende de:** 5.4, 5.5
**Entregável:** helper que formata diff legível (`"phone: '11 1' → '11 2'"`)

**Prompt para IA:**
```
Crie app/helpers/versions_helper.rb com:

module VersionsHelper
  def version_actor(version)
    return "Sistema" if version.whodunnit.blank?
    user = User.find_by(id: version.whodunnit)
    user ? "#{user.name} (#{user.role})" : "Usuário removido"
  end

  def version_changes_lines(version)
    return [] if version.object_changes.blank?
    changes = version.object_changes_hash rescue JSON.parse(version.object_changes)
    changes.except("updated_at", "created_at").map do |attr, (from, to)|
      "#{t("activerecord.attributes.#{version.item_type.underscore}.#{attr}", default: attr)}: " \
      "#{from.inspect} → #{to.inspect}"
    end
  end
end

Configurar em config/locales/pt-BR.yml as traduções dos atributos visíveis.
```

---

## FASE 6 — Polish + I18n + deploy (~3h)

### 6.1 I18n pt-BR — M
**Depende de:** todas as views existirem
**Entregável:** `config/locales/pt-BR.yml` com models, atributos, mensagens, helpers de submit

### 6.2 Helpers de formatação — B
**Depende de:** nada
**Entregável:** `app/helpers/currency_helper.rb` (`brl`), `date_helper.rb` (`dia_semana`)

### 6.3 Mailer placeholder — B
**Depende de:** nada
**Entregável:** `app/mailers/application_mailer.rb` configurado mas não usado (preparação para fase 2)

### 6.4 Procfile + Dockerfile (opcional) — M
**Depende de:** todo o projeto
**Entregável:** deploy a 1 comando em Render/Fly/Railway

```
web:     bundle exec rails server -p $PORT
worker:  bundle exec sidekiq -C config/sidekiq.yml
release: bundle exec rails db:migrate
```

### 6.5 Configurar webhook MP em produção — B
**Depende de:** 6.4
**Entregável:** painel MP apontando para `https://<domínio>/webhooks/mercadopago`

### 6.6 Smoke test em produção — M
**Depende de:** 6.5
**Entregável:** 1 fluxo end-to-end: cadastro → seleção → pagamento sandbox → confirmação visível

---

## FASE 7 — IA local (LibreChat + Ollama) — opcional (~1h)

Mantida como opcional do CONTEXT original — não bloqueia nenhuma outra tarefa.

---

## Mapa de dependências críticas

```
0.1 → 0.2 → 0.3 → 0.4 → 0.5
                │
                ▼
1.1 → 1.2 → 1.3 → 1.4 → 1.5
        │     │           │
        │     │           ▼
        │     ▼      2.1 → 2.2 → 2.3
        │     1.6
        │
        ▼
3.1 → 3.2 → 3.3
        │
        ▼
4.1 ─┬─► 4.2
     │
     ├─► 4.3 ─┐
     │        ▼
     │       4.4 ◄── 4.6
     │        │
     │        ▼
     │       4.5
     │
     │        4.6 ─► 4.7 ─► 4.8
     │                   │
     │                   ▼
     │                  4.9
     │
     │       4.10 (independente, depende de 1.5 + 4.4)
     │
     └─► 4.11
     └─► 4.12
                │
                ▼
            5.1 ─► 5.2 / 5.3 / 5.4 / 5.5 / 5.6
                │
                ▼
            6.1–6.6
```

---

## Estimativa consolidada

| Fase | Horas |
|---|---|
| 0 — Setup | 1.5h |
| 1 — DB e Models | 5h |
| 2 — Auth | 3h |
| 3 — Frontend base | 2h |
| 4 — Dentista | 9h |
| 5 — Admin | 5h |
| 6 — Polish + Deploy | 3h |
| 7 — IA local (opcional) | 1h |
| **Total** | **~28-30h** |

---

*Roadmap técnico validado e ordenado.*
