# ARCHIVE — Restyling inicial (concluído)

> **⚠️ HISTÓRICO — NÃO USE COMO GUIA**
>
> Este documento registra o plano do **restyling inicial** do `videira_dental` para o Design System (mai/2026). Já está concluído.
>
> Para criar telas novas hoje, use:
> - [`TEMPLATE_TELA_E_MODAL.md`](TEMPLATE_TELA_E_MODAL.md) — esqueletos prontos
> - [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) — tokens, classes, helpers
> - [`CATALOGO_TELAS.md`](CATALOGO_TELAS.md) — telas existentes para referência
>
> **Conteúdo original abaixo** (preservado por contexto histórico).

---

# RESTYLING_TASKS.md — Aplicar Design System ao videira_dental

> **Objetivo:** reestilizar **todas** as telas do `videira_dental` para baterem com `vdc_final/docs/DESIGN_SYSTEM.md`.
> **Prioridade absoluta:** **responsividade mobile** (smartphone). Desktop fica para depois.
> **Modelo recomendado para executar:** Sonnet 4.6.
> Data de criação: 2026-05-13

---

## Como o Sonnet deve usar este documento

1. **Ler primeiro (sem código):**
   - `vdc_final/docs/DESIGN_SYSTEM.md` — fonte da verdade visual
   - Este arquivo (`RESTYLING_TASKS.md`) — ordem de execução
2. **Executar tarefa por tarefa, em ordem.** Fase 0 antes da Fase 1, e assim por diante.
3. **1 tarefa = 1 commit atômico.** Mensagem: `style(<escopo>): <título da tarefa>`.
4. **Após cada tarefa visual**, abra a tela no browser em **viewport 375px** (iPhone SE) e verifique manualmente. Anote no commit body se ficou divergente.
5. **NÃO refatore** lógica de controller/model nestas tarefas. Mexe SÓ em views, partials, CSS e config de Tailwind.
6. **NÃO adicione** features ou textos novos. Reaproveite o conteúdo que já existe na view.
7. Se algum partial referenciado pelo DESIGN_SYSTEM.md **não existir** (ex: `_back_button`, `_logo`), **crie** dentro da fase correspondente.
8. Use `bin/dev` rodando para hot reload do Tailwind.

---

## Princípios de execução

- **Mobile-first:** todo container raiz é `<div class="max-w-md mx-auto px-4 py-6">` dentro de `<body style="background-color: #fef8e1">`. Sem media query até a Fase 7.
- **Cores via tokens (CSS vars).** Hex inline `style="color: #5D4037"` é aceito quando Tailwind utility não cobre — mas prefira `text-primary` se token configurado.
- **Botões:** sempre `rounded-full`. Primários: marrom `#5D4037` + texto branco. Outline: borda `#5D4037`.
- **Cards:** `bg-white rounded-3xl p-6 shadow-lg` (principal) ou `bg-white rounded-2xl p-4 shadow-sm` (secundário).
- **Fonte:** Prompt (Google Fonts), carregada via CSS global.
- **Sem azul** (`text-blue-*`, `bg-blue-*`) em lugar nenhum — substituir por tokens marrom.
- **Sem sidebar admin** — admin vira grid 2-col mobile-first (como Home).
- **Touch targets ≥44×44px** (botões `py-3` no mínimo).
- **Inputs em mobile:** `font-size: 16px` para evitar zoom automático do iOS.

---

## Estado atual (resumo do diagnóstico)

| O que tem hoje | O que precisa virar |
|---|---|
| `application.html.erb` com navbar topo + paleta azul/cinza | Mobile-first centralizado, paleta marrom, header simples |
| `admin.html.erb` com sidebar fixa `w-64` | Grid 2-col mobile-first com logo + logout no topo |
| `_slot_card.html.erb` retangular azul | Pill `rounded-full` com bg-`#fef8e1`/`#C9B8A8`/`#F5F5F5` |
| `_cart_summary.html.erb` azul sticky | Card branco `rounded-2xl` marrom |
| `payments/_pending.html.erb` azul | Card branco `rounded-2xl` borda `#E0E0E0` + QR centralizado |
| Devise views **não customizadas** (usam scaffold default) | Telas Login + Cadastro com tabs e estilo do design |
| Tailwind importado mas **sem tokens custom** nem fonte Prompt | `application.css` com `:root` de tokens + Prompt carregada |
| Sem partials: `_back_button`, `_logo`, `_flash`, `_avatar`, `_week_selector` | Criar conforme DESIGN_SYSTEM.md §4 |

---

# FASE 0 — Setup base (tokens, fonte, CSS global)

> Pré-requisito de **toda** tarefa visual subsequente. Sem isso, mudança vira hack inline em hex.

## T0.1 Adicionar tokens CSS e fonte Prompt à aplicação

**Arquivos:**
- `app/assets/tailwind/application.css` (atual: só `@import "tailwindcss";`)
- (opcional) `app/assets/stylesheets/application.css`

**O que fazer:**
1. Abrir `app/assets/tailwind/application.css`.
2. **Substituir** o conteúdo por (na ordem):

```css
@import url('https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600;700&display=swap');
@import "tailwindcss";

@theme {
  --color-vdc-background:        #fef8e1;
  --color-vdc-foreground:        #3E2723;
  --color-vdc-primary:           #5D4037;
  --color-vdc-primary-fg:        #ffffff;
  --color-vdc-secondary:         #8D6E63;
  --color-vdc-accent:            #C9B8A8;
  --color-vdc-accent-fg:         #3E2723;
  --color-vdc-card:              #ffffff;
  --color-vdc-border:            #E0E0E0;
  --color-vdc-destructive:       #d4183d;
  --color-vdc-success:           #388E3C;
  --color-vdc-success-bg:        #E8F5E9;
  --color-vdc-pix:               #32BCAD;

  --radius-vdc:                  0.625rem;
  --font-vdc:                    'Prompt', sans-serif;
}

:root {
  --background:        #fef8e1;
  --foreground:        #3E2723;
  --primary:           #5D4037;
  --primary-foreground:#ffffff;
  --secondary:         #8D6E63;
  --accent:            #C9B8A8;
  --accent-foreground: #3E2723;
  --card:              #ffffff;
  --card-foreground:   #3E2723;
  --border:            rgba(0, 0, 0, 0.1);
  --border-color:      #E0E0E0;
  --destructive:       #d4183d;
  --success:           #388E3C;
  --success-bg:        #E8F5E9;
  --pix-color:         #32BCAD;
  --radius:            0.625rem;
}

* { box-sizing: border-box; }

html, body {
  background-color: var(--background);
  color: var(--foreground);
  font-family: 'Prompt', sans-serif;
  font-size: 16px;
}

/* Anti-zoom em inputs no iOS */
@media screen and (max-width: 768px) {
  input, select, textarea { font-size: 16px !important; }
}

/* Helpers de paleta — usar quando não der pra escapar do hex */
.text-vdc-primary    { color: #5D4037; }
.text-vdc-secondary  { color: #8D6E63; }
.text-vdc-foreground { color: #3E2723; }
.bg-vdc-background   { background-color: #fef8e1; }
.bg-vdc-primary      { background-color: #5D4037; }
.bg-vdc-accent       { background-color: #C9B8A8; }
.bg-vdc-card         { background-color: #ffffff; }
.border-vdc-default  { border-color: #E0E0E0; }
```

**Critério de aceite:**
- [ ] `bin/dev` roda sem erro
- [ ] Inspecionar qualquer página → `body` tem `font-family: Prompt` aplicada
- [ ] DevTools Network mostra fonte Prompt carregada do Google Fonts
- [ ] Variáveis CSS aparecem em `:root` no inspetor

**Commit:** `style(theme): adiciona tokens VDC e fonte Prompt`

---

# FASE 1 — Layouts

## T1.1 Refazer `app/views/layouts/application.html.erb` mobile-first

**Arquivo:** `app/views/layouts/application.html.erb`

**O que mudar:**
- Remover `class="bg-gray-50 text-gray-900 antialiased"` do `<body>`
- Remover a `<nav>` desktop atual
- Conteúdo dentro de container `max-w-md mx-auto px-4 py-6`
- Header simples: logo centralizado + user menu compacto à direita (avatar dropdown ou botão sair)
- Flash via partial `shared/_flash` (criar na Fase 2)
- Manter os `<%= stylesheet_link_tag ... %>` e `<%= javascript_importmap_tags %>`

**Resultado esperado (referência — adapte mantendo helpers Rails):**

```erb
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <title><%= content_for(:title) || "Videira Dental" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= yield :head %>
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" href="/icon.png" type="image/png">
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body style="background-color: #fef8e1; font-family: 'Prompt', sans-serif">
    <div class="min-h-screen overflow-x-hidden">
      <div class="max-w-md mx-auto px-4 py-6">

        <%# Header: logo + user actions %>
        <div class="flex items-center justify-between mb-6">
          <%= link_to root_path, class: "flex items-center gap-2" do %>
            <%= render "shared/logo" %>
          <% end %>

          <% if user_signed_in? %>
            <div class="flex items-center gap-2">
              <%= link_to user_path(current_user), class: "p-1" do %>
                <%= render "shared/avatar", user: current_user, size: "sm" %>
              <% end %>
              <% if current_user.owner? || current_user.dentist? %>
                <%= link_to admin_root_path, class: "text-xs px-3 py-2 rounded-full border", style: "border-color: #5D4037; color: #5D4037" do %>
                  Admin
                <% end %>
              <% end %>
              <%= button_to destroy_user_session_path, method: :delete,
                    class: "p-2 hover:bg-white/50 rounded-full",
                    title: "Sair" do %>
                <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" style="color: #5D4037" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/>
                </svg>
              <% end %>
            </div>
          <% else %>
            <div class="flex gap-2">
              <%= link_to "Entrar", new_user_session_path,
                    class: "text-xs px-4 py-2 rounded-full",
                    style: "color: #5D4037" %>
              <%= link_to "Cadastro", new_user_registration_path,
                    class: "text-xs px-4 py-2 rounded-full text-white",
                    style: "background-color: #5D4037" %>
            </div>
          <% end %>
        </div>

        <%= render "shared/flash" %>

        <main>
          <%= yield %>
        </main>

      </div>
    </div>
  </body>
</html>
```

**Critério de aceite:**
- [ ] Visualizar home em viewport 375px: layout centralizado, sem scroll horizontal, fundo creme
- [ ] Logo aparece (renderiza partial — se não existir, criado em T2.3)
- [ ] Sem nenhuma classe `text-blue-*`, `bg-gray-*` no body
- [ ] Avatar do user (se logado) clicável e visível

**Commit:** `style(layout): mobile-first em application layout`

---

## T1.2 Refazer `app/views/layouts/admin.html.erb` (grid 2-col, sem sidebar)

**Arquivo:** `app/views/layouts/admin.html.erb`

**O que mudar:**
- Remover `<aside class="w-64 ...">` e toda sidebar
- Adotar mesmo container `max-w-md mx-auto px-4 py-6` da Fase 1
- Header com logo centralizado + botão sair no canto
- Grid `grid grid-cols-2 gap-3 mb-8` com cards de navegação:
  - Reservas → `admin_bookings_path`
  - Pagamentos → `admin_payments_path`
  - Disponibilidade → `admin_availabilities_path`
  - Descontos → `admin_discount_rules_path`
  - Usuários (só owner) → `admin_users_path`
  - Dashboard → `admin_root_path`
- Após o grid, `<%= yield %>` para conteúdo da página

**Referência (DESIGN_SYSTEM.md §5):** layout `admin.html.erb`.

**Adendo importante:** o item "Serviços" do menu antigo **não está** no DESIGN_SYSTEM. Remover do menu. Se a rota existir, o controller continua acessível.

**Critério de aceite:**
- [ ] Em 375px, vê-se 2 colunas de cards de navegação
- [ ] Logo no topo, botão sair à direita
- [ ] Active state quando `current_page?(path)` — borda mais escura ou bg `#C9B8A8`
- [ ] Sem `<aside>` no DOM

**Commit:** `style(layout): admin mobile-first com grid 2-col`

---

# FASE 2 — Partials compartilhados

> Criar os partials que `DESIGN_SYSTEM.md` §4 documenta e que **ainda não existem** no projeto.

## T2.1 Criar `app/views/shared/_flash.html.erb`

**Arquivo (novo):** `app/views/shared/_flash.html.erb`

**Conteúdo:** copiar de DESIGN_SYSTEM.md §4 (`_flash.html.erb`). Adapte para usar todos os tipos de flash do Rails (`notice`, `alert`, `error`, `success`).

Use Stimulus controller `flash` simples (criar em `app/javascript/controllers/flash_controller.js`) que remove o elemento após `timeout-value` (default 3000ms).

**Critério de aceite:**
- [ ] Disparar redirect com `notice:` → toast aparece top-right, marrom
- [ ] `alert:` → toast aparece vermelho `#d4183d`
- [ ] Some após 3s automaticamente

**Commit:** `style(shared): adiciona _flash partial com auto-dismiss`

---

## T2.2 Criar `app/views/shared/_back_button.html.erb`

**Arquivo (novo):** `app/views/shared/_back_button.html.erb`

**Conteúdo:** copiar de DESIGN_SYSTEM.md §4 (`_back_button.html.erb`).

**Uso:** `<%= render "shared/back_button", path: root_path %>` no topo de páginas internas (não na home).

**Critério de aceite:**
- [ ] Renderiza chevron-left marrom dentro de um botão circular
- [ ] Click leva para o `path` passado

**Commit:** `style(shared): adiciona _back_button partial`

---

## T2.3 Criar `app/views/shared/_logo.html.erb`

**Arquivo (novo):** `app/views/shared/_logo.html.erb`

**Conteúdo sugerido (provisório, até ter SVG do Figma):**

```erb
<%# Uso: <%= render 'shared/logo' %>
<div class="flex items-center gap-2">
  <span class="w-8 h-8 rounded-full flex items-center justify-center text-white font-bold text-lg"
        style="background-color: #5D4037">V</span>
  <span class="text-sm font-semibold tracking-wide" style="color: #5D4037">
    Videira Dental
  </span>
</div>
```

**Critério de aceite:**
- [ ] Aparece corretamente no header de `application` e `admin`

**Commit:** `style(shared): adiciona _logo partial`

---

## T2.4 Criar `app/views/shared/_avatar.html.erb`

**Arquivo (novo):** `app/views/shared/_avatar.html.erb`

**Conteúdo:** copiar de DESIGN_SYSTEM.md §4 (`_avatar.html.erb`).

**Adaptações:**
- Se `User` não tem `avatar_url` ou attachment, sempre cai no fallback de iniciais
- Tratar `user.name.blank?` → fallback ícone de pessoa

**Critério de aceite:**
- [ ] User com nome "Maria Silva" → exibe "MS" em círculo marrom
- [ ] User sem nome → ícone genérico
- [ ] Tamanhos `sm`, `md`, `lg` renderizam diferentes

**Commit:** `style(shared): adiciona _avatar partial com fallback de iniciais`

---

## T2.5 Reescrever `app/views/shared/_slot_card.html.erb` (pill rounded-full)

**Arquivo:** `app/views/shared/_slot_card.html.erb` (já existe — substituir)

**O que mudar:**
- Remover o card retangular azul atual
- Adotar formato **pill** (`rounded-full`) conforme DESIGN_SYSTEM.md §4 `_slot_card.html.erb`
- 3 estados visuais:
  - `:available` → bg `#fef8e1`, texto `#3E2723`
  - `:selected` (no carrinho) → bg `#C9B8A8`, texto `#3E2723`
  - `:booked` (reservado) → bg `#F5F5F5`, texto `#BDBDBD`, `disabled`, `cursor-not-allowed`
- Mostra:
  - Linha 1: nome do serviço (ou período)
  - Linha 2: horário formatado (HH às HH)
  - Direita: preço em R$
- O botão `+ Adicionar` / `✕ Remover` continua como `button_to` com Turbo Stream, mas com estilo do design (não azul)

**Atenção:** o partial atual usa `availability.service.name`, `availability.dentist.name`, `availability.service.price`, `availability.starts_at`, `availability.ends_at`, `availability.service.duration_minutes`. Manter esses atributos.

**Critério de aceite:**
- [ ] Slot livre → pill creme, texto marrom escuro, clicável
- [ ] Slot no carrinho → pill bege `#C9B8A8`
- [ ] Slot já reservado por outro → cinza claro, opaco, não clica
- [ ] Preço alinhado à direita
- [ ] Touch target inteiro >=44px de altura

**Commit:** `style(slot): pill rounded-full com 3 estados`

---

## T2.6 Reescrever `app/views/shared/_cart_summary.html.erb`

**Arquivo:** `app/views/shared/_cart_summary.html.erb`

**O que mudar:**
- Remover bg azul + borda azul atual
- Virar card branco `rounded-2xl shadow-sm` com badge marrom
- Botões: "Ver carrinho" como text-link marrom, "Confirmar e pagar" como pill marrom `rounded-full`

**Snippet de referência:**

```erb
<% cart_ids = Array(session[:cart_ids]) %>
<% count = cart_ids.size %>

<% if count > 0 %>
  <div class="sticky top-4 z-10 mb-6 bg-white rounded-2xl shadow-md px-4 py-3 flex items-center justify-between">
    <div class="flex items-center gap-3">
      <span class="inline-flex items-center justify-center w-7 h-7 text-white text-sm font-bold rounded-full"
            style="background-color: #5D4037"><%= count %></span>
      <span class="text-sm font-medium" style="color: #5D4037">
        <%= pluralize(count, "horário", "horários") %>
      </span>
    </div>
    <%= link_to "Confirmar →", confirmar_reservas_path,
          class: "text-xs font-semibold px-4 py-2 rounded-full text-white",
          style: "background-color: #5D4037" %>
  </div>
<% end %>
```

**Critério de aceite:**
- [ ] Sticky no topo enquanto rola
- [ ] Sem azul nenhum
- [ ] Botão "Confirmar →" rounded-full marrom
- [ ] Funciona em 375px sem quebra

**Commit:** `style(cart): cart_summary com tokens do design`

---

## T2.7 Criar Stimulus `flash_controller.js`

**Arquivo (novo):** `app/javascript/controllers/flash_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 3000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.timeoutValue)
  }

  disconnect() { clearTimeout(this.timer) }

  dismiss() {
    this.element.style.transition = "opacity 200ms"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 200)
  }
}
```

Registrar em `app/javascript/controllers/index.js` se for autoload manual.

**Critério de aceite:**
- [ ] Toast some sozinho após 3s
- [ ] Click no toast também remove (opcional — adicionar `data-action="click->flash#dismiss"` no _flash)

**Commit:** `style(js): flash_controller com auto-dismiss`

---

# FASE 3 — Páginas públicas (não autenticadas)

## T3.1 Reescrever `app/views/pages/home.html.erb`

**Arquivo:** `app/views/pages/home.html.erb`

**O que mudar:**
- Remover Hero `text-4xl font-bold text-gray-900` desktop
- Adotar título compacto mobile: `h1 text-2xl mb-2` marrom
- Subtítulo `text-sm` cinza-marrom
- Date filter num card branco `rounded-2xl shadow-sm p-4`
- Grid de slots vira **lista vertical** (`flex flex-col gap-3`) — não grid 3-col
- Mantém `turbo_frame_tag "cart-summary"` antes da lista

**Snippet de referência:**

```erb
<% content_for :title, "Videira Dental — Agende sua sala" %>

<div class="mb-6 text-center">
  <h1 class="text-2xl font-semibold mb-1" style="color: #5D4037">Reserve sua sala</h1>
  <p class="text-sm" style="color: #8D6E63">Escolha o horário e pague com Pix.</p>
</div>

<%# Filtro de data — card branco %>
<div class="bg-white rounded-2xl shadow-sm p-4 mb-4">
  <%= form_with url: root_path, method: :get, data: { turbo: false }, class: "flex flex-col gap-2" do |f| %>
    <label class="text-xs font-medium" style="color: #5D4037">Data</label>
    <%= f.date_field :date, value: @date,
          class: "w-full px-4 py-3 rounded-2xl border text-sm bg-white",
          style: "border-color: #E0E0E0; color: #3E2723",
          onchange: "this.form.submit()" %>
  <% end %>
</div>

<%# Carrinho flutuante %>
<%= turbo_frame_tag "cart-summary" do %>
  <%= render "shared/cart_summary" %>
<% end %>

<%# Slots do dia %>
<% if @availabilities.empty? %>
  <div class="text-center py-12">
    <p class="text-sm" style="color: #8D6E63">Nenhum horário disponível para esta data.</p>
  </div>
<% else %>
  <div id="availability-grid" class="flex flex-col gap-3">
    <% @availabilities.each do |av| %>
      <%= render "shared/slot_card", availability: av %>
    <% end %>
  </div>
<% end %>
```

**Critério de aceite:**
- [ ] Em 375px, lista vertical de slots, sem grid lateral
- [ ] Date input não causa zoom no iOS
- [ ] Sem texto azul nem botão azul

**Commit:** `style(home): mobile-first home com lista vertical`

---

## T3.2 Reescrever `app/views/scheduling/carts/show.html.erb`

**Arquivo:** `app/views/scheduling/carts/show.html.erb`

**Manter:** estrutura de listagem dos itens + total + botão de checkout.

**Aplicar:**
- Wrapper já vem do layout — não duplicar `max-w-md`
- Back button no topo: `<%= render "shared/back_button", path: root_path %>`
- H1 `text-2xl mb-6` marrom: "Meu carrinho"
- Cada item: card branco `rounded-2xl shadow-sm p-4 mb-3` com info + botão remover (outline marrom)
- Bloco de total: card branco maior `rounded-3xl shadow-lg p-6`, com badge de desconto verde se houver
- CTA principal: pill `rounded-full` marrom, full-width

**Critério de aceite:**
- [ ] Sem azul
- [ ] Badge de desconto: bg `#E8F5E9`, texto `#388E3C` (ver DESIGN_SYSTEM §3 "Badge de desconto")
- [ ] Botão "Confirmar e ir para pagamento" full-width pill marrom

**Commit:** `style(cart): cart show com tokens VDC`

---

## T3.3 Estilizar `app/views/pages/about.html.erb` e `app/views/pages/contact.html.erb`

**Arquivos:**
- `app/views/pages/about.html.erb`
- `app/views/pages/contact.html.erb`

**O que fazer:**
- Wrapping já vem do layout
- Back button no topo
- H1 `text-2xl mb-4` marrom
- Conteúdo em `text-sm leading-relaxed` cor `#3E2723`
- Cards para seções, se houver

**Critério de aceite:**
- [ ] Visual coerente com home, sem stylings divergentes

**Commit:** `style(pages): about + contact com tokens VDC`

---

# FASE 4 — Auth (Devise)

> Devise ainda usa scaffold default. Precisa gerar e customizar.

## T4.1 Gerar views Devise

**Comando:**

```bash
bin/rails generate devise:views users
```

Isso cria `app/views/users/sessions/`, `app/views/users/registrations/`, `app/views/users/passwords/`, etc.

**Confirmar:** `config/initializers/devise.rb` está com `config.scoped_views = true` ou ajustar para `false` se preferir reutilizar `devise/...`.

**Critério de aceite:**
- [ ] Views geradas em `app/views/users/` (ou `app/views/devise/`)
- [ ] `bin/dev` continua subindo
- [ ] `/users/sign_in` renderiza (ainda feio, mas sem 500)

**Commit:** `chore(devise): gera scoped views`

---

## T4.2 Reescrever Login (`sessions/new`) com tabs

**Arquivo:** `app/views/users/sessions/new.html.erb` (ou `app/views/devise/sessions/new.html.erb`)

**Layout:**

```erb
<% content_for :title, "Entrar" %>

<div class="mb-6">
  <%= render "shared/back_button", path: root_path %>
</div>

<h1 class="text-2xl mb-2" style="color: #5D4037">Bem-vindo de volta</h1>
<p class="text-sm mb-8" style="color: #8D6E63">Entre na sua conta para reservar</p>

<%# Tabs %>
<div class="flex gap-4 mb-8 border-b" style="border-color: #E0E0E0">
  <button class="pb-3 px-1 border-b-2 transition-colors text-sm font-medium"
          style="border-color: #5D4037; color: #5D4037">
    Entrar
  </button>
  <%= link_to new_user_registration_path, class: "pb-3 px-1 text-sm text-gray-400" do %>
    Criar conta
  <% end %>
</div>

<%= form_for(resource, as: resource_name, url: session_path(resource_name), html: { class: "flex flex-col gap-4" }) do |f| %>
  <%= f.email_field :email, autofocus: true, autocomplete: "email",
        placeholder: "E-mail*",
        class: "w-full px-4 py-3 rounded-2xl border text-sm bg-white",
        style: "border-color: #E0E0E0; color: #3E2723" %>

  <div class="relative" data-controller="password-toggle">
    <%= f.password_field :password, autocomplete: "current-password",
          placeholder: "Senha*",
          class: "w-full px-4 py-3 rounded-2xl border text-sm pr-12 bg-white",
          style: "border-color: #E0E0E0; color: #3E2723",
          data: { "password-toggle-target": "input" } %>
    <button type="button"
            class="absolute right-4 top-1/2 -translate-y-1/2"
            data-action="click->password-toggle#toggle"
            aria-label="Mostrar senha">
      <%# olho SVG simplificado %>
      <svg class="w-5 h-5" style="color: #8D6E63" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
      </svg>
    </button>
  </div>

  <% if devise_mapping.rememberable? %>
    <label class="flex items-center gap-2 text-sm" style="color: #3E2723">
      <%= f.check_box :remember_me, class: "w-4 h-4 rounded" %>
      Lembrar de mim
    </label>
  <% end %>

  <%= f.submit "Entrar", class: "w-full py-3 rounded-full text-white text-sm font-medium",
        style: "background-color: #5D4037" %>
<% end %>

<%# OAuth Google %>
<div class="mt-6 text-center">
  <p class="text-xs mb-3" style="color: #8D6E63">ou</p>
  <%= button_to user_google_oauth2_omniauth_authorize_path, method: :post, data: { turbo: false },
        class: "w-full py-3 rounded-full border-2 text-sm font-medium flex items-center justify-center gap-2",
        style: "border-color: #5D4037; color: #5D4037" do %>
    Entrar com Google
  <% end %>
</div>

<div class="mt-6 text-center text-sm" style="color: #8D6E63">
  <%= link_to "Esqueci minha senha", new_password_path(resource_name),
        class: "underline" %>
</div>
```

**Criar também** Stimulus `password_toggle_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["input"]
  toggle() {
    this.inputTarget.type = this.inputTarget.type === "password" ? "text" : "password"
  }
}
```

**Critério de aceite:**
- [ ] Em 375px, form caberá tudo sem scroll horizontal
- [ ] Tabs "Entrar" / "Criar conta" navegam
- [ ] Olho mostra/oculta senha
- [ ] OAuth Google funciona (rota existente — apenas estilizar botão)

**Commit:** `style(devise): sessions/new com tabs e tokens VDC`

---

## T4.3 Reescrever Cadastro (`registrations/new`)

**Arquivo:** `app/views/users/registrations/new.html.erb`

**Layout:** Mesma estrutura de tabs do Login, mas a aba "Criar conta" é a ativa.

**Campos (ver DESIGN_SYSTEM.md §8):**
- Nome completo (`name`)
- E-mail (`email`)
- Senha (`password`) + toggle olho
- Confirmar senha (`password_confirmation`) + toggle olho
- Telefone (`phone`) — se houver no model, com mask Stimulus
- Registro CRO (`cro_number`) — se houver no model
- Área de atuação (`specialty`) — se houver no model
- Checkbox de aceite de termos (`terms_accepted`)

**Adendo:** se algum campo desses **não existe** no `User` model, **não criar migration agora**. Apenas omita o campo e deixe nota TODO no commit body.

**Botão submit:** "Criar conta" pill marrom full-width.

**Critério de aceite:**
- [ ] Form caberá em 375px com scroll vertical natural
- [ ] Cada input com border `#E0E0E0`, rounded-2xl
- [ ] Aceite de termos com link sublinhado azul-info (`#2196F3`) **só** nesse trecho (única exceção à regra de "sem azul")
- [ ] Tab "Entrar" leva para login

**Commit:** `style(devise): registrations/new com campos VDC`

---

## T4.4 Estilizar `passwords/new`, `passwords/edit`, `confirmations`, `unlocks`

**Arquivos:** demais views Devise geradas.

**Padrão:**
- Back button para login
- H1 marrom `text-2xl mb-2`
- Subtítulo cinza-marrom
- Inputs `rounded-2xl`
- Botão submit pill marrom

**Critério de aceite:**
- [ ] Fluxo "esqueci senha" navega visualmente coerente com login

**Commit:** `style(devise): passwords/confirmations/unlocks com tokens VDC`

---

# FASE 5 — Fluxo do dentista (autenticado)

## T5.1 Reescrever `app/views/scheduling/bookings/index.html.erb` (Minhas Reservas)

**Arquivo:** `app/views/scheduling/bookings/index.html.erb`

**Layout:**
- Back button → home
- H1 "Minhas reservas" `text-2xl mb-6` marrom
- Agrupar por mês: cada grupo com título `text-lg mb-3` marrom
- Cada reserva = card branco `rounded-2xl shadow-sm p-4 mb-3`:
  - Nome do serviço (text-base font-medium marrom escuro)
  - Data + horário (text-sm cinza-marrom)
  - Status pill no canto: "Confirmada" verde `#388E3C` / "Pendente" amarelo / "Cancelada" vermelho `#d4183d`
  - Click → vai pra `/bookings/:id` (show)

**Empty state:** texto centralizado + CTA "Reservar agora" pill marrom.

**Critério de aceite:**
- [ ] Em 375px, lista vertical, sem cortes
- [ ] Status com cor adequada

**Commit:** `style(bookings): index com cards e agrupamento por mês`

---

## T5.2 Reescrever `app/views/scheduling/bookings/show.html.erb`

**Arquivo:** `app/views/scheduling/bookings/show.html.erb`

**Layout:**
- Back button → minhas reservas
- Card principal grande `rounded-3xl shadow-lg p-6` com:
  - Status badge no topo (mesmo padrão do index)
  - Serviço, data, horário, valor
  - Linha separadora `border-t` `#E0E0E0`
- Card secundário com info da clínica/dentista
- Botões de ação no rodapé:
  - "Cancelar reserva" (outline destructive `#d4183d`) — só se permitido (>48h)
  - "Ver pagamento" → leva para `payments/show` se booking_group tem payment

**Critério de aceite:**
- [ ] Sem azul
- [ ] Botão cancelar sumida quando <48h

**Commit:** `style(bookings): show com cards detalhados`

---

## T5.3 Reescrever `app/views/scheduling/bookings/new.html.erb` (Confirmar Reserva)

**Arquivo:** `app/views/scheduling/bookings/new.html.erb`

**Layout:**
- Back button
- H1 "Confirmar reserva"
- Lista resumida dos slots selecionados (cada um em card branco `rounded-2xl`)
- Bloco de cálculo: subtotal, badge de desconto se aplicável (`bg #E8F5E9 text #388E3C`), total final
- Botão grande `rounded-full` marrom "Confirmar e gerar Pix"

**Critério de aceite:**
- [ ] Desconto destacado em verde quando >0
- [ ] Total final em destaque (`text-xl font-bold` marrom)

**Commit:** `style(bookings): new (confirmar reserva) com card de resumo`

---

## T5.4 Reescrever `app/views/payments/_pending.html.erb`

**Arquivo:** `app/views/payments/_pending.html.erb`

**Mudanças:**
- Card branco `rounded-2xl` borda `#E0E0E0` (não `border-gray-200`)
- Badge "Aguardando pagamento" no topo: `text-xs px-3 py-1 rounded-full`, bg `#fef8e1`, texto `#5D4037`
- QR code centralizado em `w-48 h-48 mx-auto mb-4`
- Bloco copia-cola: bg `#fef8e1 rounded-xl p-3 mb-3`
- Botão copiar: pill outline marrom (não azul)
- Countdown: `text-2xl font-bold font-mono` marrom
- Botão cancelar: `text-sm` vermelho `#d4183d` sublinhado, sem bg

**Critério de aceite:**
- [ ] Sem azul nenhum
- [ ] Em 375px, QR centralizado, copia-cola não causa overflow
- [ ] Countdown atualizando

**Commit:** `style(payments): _pending com tokens VDC`

---

## T5.5 Reestilizar `_paid.html.erb` e `_expired.html.erb`

**Arquivos:**
- `app/views/payments/_paid.html.erb`
- `app/views/payments/_expired.html.erb`

**Padrão:**
- `_paid`: card branco, ícone check verde grande, "Pagamento confirmado!" `text-2xl` verde `#388E3C`, link "Ver minhas reservas" pill marrom
- `_expired`: card branco, ícone X cinza, "Pagamento expirado" `text-2xl` marrom, "Refazer reserva" pill marrom

**Critério de aceite:**
- [ ] Estados visualmente distintos e claros
- [ ] CTAs claros

**Commit:** `style(payments): _paid e _expired com tokens VDC`

---

## T5.6 Reescrever `app/views/payments/show.html.erb` (wrapper)

**Arquivo:** `app/views/payments/show.html.erb`

**Wrapper:**
- Back button para minhas reservas
- H1 "Pagamento" `text-2xl mb-6` marrom
- Resumo curto do pedido (1 linha) acima do bloco do estado
- `<%= turbo_stream_from "payment_#{@payment.id}" %>` mantém
- `<turbo-frame id="payment_status">` envolvendo o partial conforme estado

**Critério de aceite:**
- [ ] Visual consistente com booking show
- [ ] Polling/broadcast funcionando (não mexer na lógica)

**Commit:** `style(payments): show wrapper com layout mobile-first`

---

# FASE 6 — Admin

> Mantém grid de navegação no layout (T1.2). Cada índice de admin **só** muda visual.

## T6.1 Reescrever `app/views/admin/dashboard/index.html.erb`

**Arquivo:** `app/views/admin/dashboard/index.html.erb`

**Conteúdo:**
- H1 "Dashboard" `text-2xl mb-4` marrom
- Cards de métricas em grid 2-col: reservas do mês, pagamentos pendentes, receita mês, clientes ativos
- Cada card: branco `rounded-2xl shadow-sm p-4`, número grande marrom, label cinza-marrom abaixo

**Critério de aceite:**
- [ ] Em 375px, 2 colunas legíveis
- [ ] Números destacados

**Commit:** `style(admin): dashboard com cards de métricas`

---

## T6.2 Reescrever `admin/bookings/index.html.erb` e `show.html.erb`

**Arquivos:**
- `app/views/admin/bookings/index.html.erb`
- `app/views/admin/bookings/show.html.erb`

**Index:**
- H1 "Reservas" marrom
- Filtro por data: card branco com `date_field` rounded-2xl
- Lista de reservas: cada uma card branco `rounded-2xl p-4 mb-3` com nome do dentista, serviço, data, status
- Click → show

**Show:**
- Back button → index
- Card grande com todos os dados
- Botão "Cancelar" outline destructive se aplicável

**Critério de aceite:**
- [ ] Filtro funciona em mobile sem zoom
- [ ] Cards clicáveis (área toda)

**Commit:** `style(admin/bookings): index e show com tokens VDC`

---

## T6.3 Reescrever `admin/users/index|show|edit.html.erb`

**Arquivos:** os 3 do admin/users.

**Padrão:**
- Index: busca no topo (input rounded-2xl), lista de cards com avatar + nome + CRO/role
- Show: card grande com dados pessoais + sub-card com histórico de reservas
- Edit: form com inputs rounded-2xl, botão pill marrom

**Critério de aceite:**
- [ ] Busca em mobile não causa zoom
- [ ] Avatares aparecem usando _avatar partial

**Commit:** `style(admin/users): index, show e edit com tokens VDC`

---

## T6.4 Reescrever `admin/availabilities/index|new|edit|_form.html.erb`

**Arquivos:** todos do admin/availabilities.

**Padrão:**
- Index: agrupar por dia, cada slot como pill (reuso de `_slot_card` adaptado ou inline parecido)
- New/edit: form em card branco, inputs rounded-2xl, botão pill marrom

**Critério de aceite:**
- [ ] Form funcional (sem mexer lógica)
- [ ] Visual coerente

**Commit:** `style(admin/availabilities): index e form com tokens VDC`

---

## T6.5 Reescrever `admin/discount_rules/index|new|edit|_form.html.erb`

**Arquivos:** todos do admin/discount_rules.

**Padrão:**
- Index: lista de regras como cards (mín slots → desconto)
- Form: inputs rounded-2xl, botão pill marrom

**Critério de aceite:**
- [ ] CRUD funcional sem mudança de comportamento
- [ ] Visual coerente

**Commit:** `style(admin/discounts): index e form com tokens VDC`

---

## T6.6 Reescrever `admin/payments/index|show.html.erb`

**Arquivos:** os 2 do admin/payments.

**Padrão:**
- Index: lista de pagamentos com status badge (pendente/pago/expirado)
- Show: detalhes do payment com link pro booking_group

**Critério de aceite:**
- [ ] Status badges coerentes com cores da Fase 5

**Commit:** `style(admin/payments): index e show com tokens VDC`

---

# FASE 7 — Auditoria de responsividade e polish

## T7.1 Auditoria visual em viewports comuns

**O que fazer:**

Abrir Chrome DevTools → Toggle Device Toolbar. Testar:
- iPhone SE (375 × 667)
- iPhone 12/13/14 (390 × 844)
- Samsung Galaxy S20 (360 × 800)

Páginas a verificar (em ordem):
1. `/` (home)
2. `/users/sign_in`
3. `/users/sign_up`
4. `/carrinho`
5. `/reservas/confirmar`
6. `/pagamento/:id` (em todos os 3 estados)
7. `/minhas-reservas`
8. `/admin`
9. Cada admin/*

**Critério de aceite:**
- [ ] Zero scroll horizontal em qualquer página
- [ ] Touch targets >=44×44px (botões, links importantes)
- [ ] Texto legível sem zoom (>=14px)
- [ ] Inputs não disparam zoom no iOS (font-size >=16px)
- [ ] Logo, header, footer (se houver) não cortam
- [ ] Cards não estouram em telas estreitas (360px)

**Anotações:** Criar `docs/RESTYLING_AUDIT.md` com screenshots/notas dos problemas + correção feita.

**Commit:** `style(audit): polish de responsividade mobile`

---

## T7.2 Auditoria de acessibilidade básica

**O que fazer:**
- Rodar Lighthouse mobile no Chrome em 5 telas principais
- Verificar contraste AA (4.5:1) para todo texto sobre fundo
- Adicionar `alt=""` em todas as imagens decorativas e `alt="<descrição>"` em informativas
- Adicionar `aria-label` em botões só com ícone (cancelar, fechar, olho de senha)

**Critério de aceite:**
- [ ] Lighthouse Accessibility >= 90 em mobile nas 5 telas principais
- [ ] Sem violação de contraste reportada

**Commit:** `a11y: ajustes de acessibilidade pós-restyling`

---

## T7.3 Atualizar CONTEXT.md com decisões de design

**Arquivo:** `CONTEXT.md`

Adicionar seção:

```markdown
## Restyling para Design System (2026-05-XX)

### Decisões
- **Mobile-first com `max-w-md` (448px).** Desktop fica para fase posterior.
- **Sem azul/cinza Tailwind default** — paleta marrom VDC apenas.
- **Admin sem sidebar** — grid de cards 2-col, igual ao mobile da home.
- **Devise:** scoped views em `app/views/users/*`.
- **Stimulus:** `flash_controller` para auto-dismiss de toasts, `password_toggle_controller` para olho de senha.

### Convenção de aplicação de cor
- Quando Tailwind utility não cobre, usar `style="color: #XXXXXX"` inline.
- Não criar classes utilitárias custom até a Fase 7.

### Não cobertos (TODO depois)
- Tema dark mode (DESIGN_SYSTEM não cobre)
- Animações `motion/react` originais — substituídas por CSS transitions simples
- Logo SVG do Figma (usando placeholder de iniciais "V" por enquanto)
```

**Commit:** `docs: registra decisões do restyling em CONTEXT.md`

---

# Resumo executivo — checklist macro

- [ ] **Fase 0:** Tokens CSS + fonte Prompt → `application.css`
- [ ] **Fase 1:** 2 layouts (application + admin) mobile-first
- [ ] **Fase 2:** 6 partials novos/atualizados + 1 stimulus controller
- [ ] **Fase 3:** 4 views públicas (home, carrinho, about, contact)
- [ ] **Fase 4:** 4 telas Devise (login, signup, password, confirmation)
- [ ] **Fase 5:** 6 views do fluxo de booking + payment
- [ ] **Fase 6:** ~11 views admin
- [ ] **Fase 7:** Auditoria + acessibilidade + doc de decisões

**Total estimado:** ~30 commits / 12-18h de trabalho focado para Sonnet.

---

## Estratégia de prompt sugerida para chamar Sonnet

```
Tarefa: RESTYLING_TASKS.md §T<X.Y>
Referência visual: vdc_final/docs/DESIGN_SYSTEM.md
Restrições:
- Só estilização (views, CSS, partials, stimulus de UI). NÃO mexer em controller, model, service, migration.
- Mobile-first em viewport 375px. Sem media query até Fase 7.
- Sem azul/cinza Tailwind. Paleta VDC apenas.
- Touch targets >=44px.
- Inputs com font-size 16px em mobile.

Após implementar:
1. Mostrar `git diff` da tarefa
2. Listar arquivos tocados
3. Sugerir mensagem de commit

Se algo do design system não estiver claro, pare e pergunte. Não invente.
```

---

## Critério de "pronto"

A reestilização está completa quando:

- [ ] Todas as 7 fases concluídas com commits atômicos
- [ ] `RESTYLING_AUDIT.md` criado e aprovado
- [ ] Lighthouse Mobile Accessibility >= 90 nas 5 telas principais
- [ ] Zero ocorrência de `text-blue-*`, `bg-blue-*`, `text-gray-*` no diff total (busca: `grep -rn "text-blue\|bg-blue\|text-gray" app/views/`)
- [ ] Visual coerente em 360/375/390/414 px
- [ ] `CONTEXT.md` atualizado com decisões

---

## Apêndice — busca rápida de "lugares ainda fora do padrão"

Para verificar progresso, rodar de tempos em tempos:

```bash
# Restos da paleta antiga
grep -rn "text-blue\|bg-blue\|text-gray\|bg-gray" app/views/ | wc -l

# Achar views ainda sem rounded-2xl ou rounded-full
grep -rL "rounded-2xl\|rounded-full\|rounded-3xl" app/views/ | grep -v turbo_stream

# Achar arquivos sem cor de design (sondagem)
grep -rL "5D4037\|fef8e1\|8D6E63" app/views/
```

> Esses comandos servem só como **indicador** — não como gate. Conferência visual ainda é necessária.
