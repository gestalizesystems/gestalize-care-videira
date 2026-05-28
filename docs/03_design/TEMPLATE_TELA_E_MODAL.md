# Template de Tela e Modal — Videira Dental

> Esqueletos prontos para copiar ao criar **qualquer nova tela ou modal**.
> Garante consistência visual com [[DESIGN_SYSTEM]] sem precisar reinventar a estrutura.
>
> **Quando usar:** sempre que for criar uma view nova (`*.html.erb`) ou um modal/dialog.

---

## Princípios (memorize estes 5)

1. **Mobile-first.** Container raiz é sempre `max-w-md mx-auto px-4 py-6` (já vem do layout).
2. **Cards brancos arredondados.** `rounded-2xl` (secundário) ou `rounded-3xl` (principal).
3. **Botões pill lado a lado.** Sempre `rounded-full`. Outline à esquerda (`btn-outline flex-1`), preenchido à direita (`btn-primary flex-1`). Container: `flex gap-3`.
4. **Sem azul/cinza Tailwind default.** Só a paleta VDC (marrom, creme, bege).
5. **Inputs com `font-size: 16px`** em mobile (já garantido pelo CSS global).

> Para detalhes de tokens e cores, consultar [[DESIGN_SYSTEM]] §2 e §9.

---

## 1 · Esqueleto base de uma TELA

Use este template para qualquer view nova. Adapte o conteúdo interno; mantenha a estrutura.

```erb
<% content_for :title, "Nome da tela" %>

<%# Voltar — só em telas internas, não na home %>
<%= render "shared/back_button", path: caminho_anterior_path %>

<%# Título da página %>
<h1 class="text-2xl font-medium mb-6" style="color: #3E2723">Título da tela</h1>

<%# Erros (se houver formulário) %>
<%= render "shared/form_errors", object: @recurso if @recurso&.errors&.any? %>

<%# CONTEÚDO PRINCIPAL — escolha um dos padrões abaixo %>
```

### Variação A — Tela com formulário

> Padrão do Figma: **um card branco único** envolve tabs + campos. Inputs com **borda visível**
> `#E0E0E0` e `rounded-2xl`. Sem card individual por campo.

```erb
<div class="bg-white rounded-3xl shadow-lg p-6">

  <%# Tabs (quando a tela tem Entrar / Criar conta) %>
  <div class="flex border-b mb-6" style="border-color: #E0E0E0">
    <%= link_to "Entrar", new_user_session_path,
          class: "flex-1 text-center pb-3 text-sm font-medium",
          style: "color: #BDBDBD" %>
    <span class="flex-1 text-center pb-3 border-b-2 text-sm font-bold"
          style="border-color: #3E2723; color: #3E2723; margin-bottom: -1px">
      Criar conta
    </span>
  </div>

  <%= form_with model: @recurso, url: caminho_path, method: :post,
        class: "flex flex-col gap-3" do |f| %>

    <%# Input simples com borda %>
    <%= f.text_field :campo,
          placeholder: "Campo*",
          class: "w-full px-4 py-3 rounded-2xl border text-sm",
          style: "border-color: #E0E0E0; color: #3E2723" %>

    <%# Input com ícone à direita (ex: senha) %>
    <div class="flex items-center rounded-2xl border px-4"
         style="border-color: #E0E0E0"
         data-controller="password-toggle">
      <%= f.password_field :password,
            placeholder: "Senha*",
            class: "flex-1 py-3 text-sm bg-transparent border-none outline-none",
            style: "color: #3E2723",
            data: { "password-toggle-target": "input" } %>
      <button type="button" class="shrink-0 ml-2"
              data-action="click->password-toggle#toggle" aria-label="Mostrar senha">
        <%# ícone olho SVG %>
      </button>
    </div>

    <%# Botões: outline à esquerda, preenchido à direita %>
    <div class="flex gap-3 pt-2">
      <%= link_to "Cancelar", caminho_anterior_path, class: "btn-outline flex-1 text-center" %>
      <%= f.submit "Salvar", class: "btn-primary flex-1 cursor-pointer" %>
    </div>

  <% end %>
</div>
```

**Quando a tela NÃO tem card externo** (ex: editar perfil com labels), use o padrão de label + card por campo:
```erb
<div>
  <%= f.label :campo, "Label", class: "block text-xs font-medium mb-1 px-1", style: "color: #8D6E63" %>
  <div class="bg-white rounded-2xl shadow-sm px-4 py-1">
    <%= f.text_field :campo,
          placeholder: "Placeholder",
          class: "w-full bg-transparent border-none outline-none py-3 text-sm",
          style: "color: #3E2723" %>
  </div>
</div>
```

### Variação B — Tela de listagem

> Padrão visual alinhado com a tela `reservas/confirmar`: cards brancos `rounded-2xl shadow-sm`,
> botão de ação primária `rounded-full` com inline style, separador `border-t` entre info e total.
>
> **Regra obrigatória:** cada item da lista **deve ter `bg-white` explícito**. Não use apenas
> `card-sm` em elementos clicáveis (`link_to`, `button_to`) — a classe utilitária pode não
> aplicar o fundo corretamente em tags `<a>`. Sempre use as classes expandidas:
> `block bg-white rounded-2xl shadow-sm p-4`.

```erb
<%# Filtro (opcional) %>
<div class="bg-white rounded-2xl shadow-sm p-4 mb-4">
  <%= form_with url: caminho_path, method: :get, data: { turbo: false } do |f| %>
    <%= f.date_field :data, value: @data,
          class: "w-full px-4 py-3 rounded-2xl border text-sm bg-white",
          style: "border-color: #E0E0E0; color: #3E2723",
          onchange: "this.form.submit()" %>
  <% end %>
</div>

<%# Empty state %>
<% if @itens.empty? %>
  <div class="text-center py-12">
    <p class="text-sm mb-6" style="color: #8D6E63">Nada por aqui ainda.</p>
    <%= link_to novo_item_path,
          class: "block w-full py-3 rounded-full text-white text-sm font-medium text-center",
          style: "background-color: #5D4037" do %>
      Criar primeiro
    <% end %>
  </div>
<% else %>
  <%# Lista vertical de cards — cada item é um card branco clicável %>
  <div class="flex flex-col gap-3 mb-4">
    <% @itens.each do |item| %>
      <%= link_to item_path(item),
            class: "block bg-white rounded-2xl shadow-sm p-4 hover:shadow-md transition-all active:scale-[0.98]" do %>

        <%# Cabeçalho do card: identificador + badge de status %>
        <div class="flex items-center justify-between mb-3">
          <span class="text-xs" style="color: #8D6E63"><%= item.identificador %></span>
          <span class="<%= status_class(item.status) %>" style="<%= status_style(item.status) %>">
            <%= t("modelo.status.#{item.status}") %>
          </span>
        </div>

        <%# Corpo: título e subtítulo %>
        <div class="flex flex-col gap-1 mb-3">
          <p class="font-medium text-sm" style="color: #3E2723"><%= item.titulo %></p>
          <p class="text-xs" style="color: #8D6E63"><%= item.subtitulo %></p>
        </div>

        <%# Rodapé com separador: info secundária + valor em destaque %>
        <div class="flex justify-between items-center border-t pt-3" style="border-color: #E0E0E0">
          <span class="text-xs" style="color: #8D6E63"><%= item.info_rodape %></span>
          <span class="text-sm font-bold" style="color: #5D4037">R$ <%= money(item.valor_cents) %></span>
        </div>

      <% end %>
    <% end %>
  </div>
<% end %>
```

**Botão de ação primária** (fora da listagem — ex: CTA principal da tela):
```erb
<%= link_to acao_path,
      class: "block w-full py-3 rounded-full text-white text-sm font-medium text-center",
      style: "background-color: #5D4037" do %>
  Texto da ação →
<% end %>
```

### Variação C — Tela de detalhe (show)

> O fundo da página é sempre creme (`#fef8e1`). Todo o conteúdo do show deve estar dentro de
> cards **com `bg-white` explícito** — nunca solto sobre o fundo. Use `rounded-3xl` para o card
> principal e `rounded-2xl` para cards secundários.
>
> **Quando o show tem uma lista de itens** (ex: turnos de uma reserva), cada item deve ser um
> card branco individual `rounded-2xl` — nunca linhas com `divide-y` dentro de um único card.
> O resumo/total fica em um card separado `rounded-3xl` abaixo da lista.

```erb
<%# Cabeçalho fora do card: título + badge de status %>
<div class="flex items-center justify-between mb-4">
  <h1 class="text-2xl font-medium" style="color: #5D4037">Título</h1>
  <span class="<%= status_class(item.status) %>" style="<%= status_style(item.status) %>">
    <%= t("modelo.status.#{@recurso.status}") %>
  </span>
</div>

<%# Lista de itens: cada um como card branco individual %>
<div class="flex flex-col gap-3 mb-4">
  <% @recurso.itens.each do |item| %>
    <div class="bg-white rounded-2xl shadow-sm p-4 flex justify-between items-start">
      <div>
        <p class="font-medium text-sm" style="color: #3E2723"><%= item.titulo %></p>
        <p class="text-xs mt-1" style="color: #8D6E63"><%= item.subtitulo %></p>
      </div>
      <span class="text-sm font-medium" style="color: #5D4037">R$ <%= money(item.valor_cents) %></span>
    </div>
  <% end %>
</div>

<%# Resumo/total em card separado %>
<div class="bg-white rounded-3xl shadow-lg p-6 mb-4">
  <div class="flex justify-between text-sm mb-2" style="color: #8D6E63">
    <span>Subtotal</span>
    <span>R$ <%= money(@recurso.subtotal_cents) %></span>
  </div>
  <div class="flex justify-between font-medium border-t pt-3 mt-1" style="border-color: #E0E0E0">
    <span style="color: #3E2723">Total</span>
    <span class="text-xl font-medium" style="color: #5D4037">R$ <%= money(@recurso.total_cents) %></span>
  </div>
</div>

<%# CTA principal (ação única, largura total) — mesmo estilo do botão "Confirmar" %>
<%= link_to "Texto da ação →", acao_path,
      class: "block w-full py-3 rounded-full text-white text-sm font-medium text-center",
      style: "background-color: #5D4037" %>

<%# Ações secundárias lado a lado: outline à esquerda, preenchido à direita %>
<div class="flex gap-3 mt-3">
  <%= link_to "Voltar", caminho_anterior_path, class: "btn-outline flex-1 text-center" %>
  <%= link_to "Ação primária", acao_path, class: "btn-primary flex-1 text-center" %>
</div>
```

---

## 2 · Esqueleto base de um MODAL

Modais usam o elemento `<dialog>` nativo do HTML. O CSS global (`application.css`) já centraliza
todos os `<dialog>` automaticamente — **não adicione nenhuma classe de posicionamento inline**.

### Regras obrigatórias

- **Sempre** use o partial `shared/_modal` (veja abaixo) — nunca escreva `<dialog>` do zero.
- **Sempre** abra via `open_modal` helper → `onclick="<%= open_modal('id-do-modal') %>"`.
  O helper garante que `.showModal()` é chamado (obrigatório para o backdrop e o centering).
- **Nunca** use `.show()` em vez de `.showModal()`.
- **Nunca** adicione classes de posição/transform/margin no `<dialog>` — o CSS global cuida disso.
- Fechar ao clicar fora: `onclick="if(event.target===this)this.close()"` (já incluso no partial).
- `Esc` fecha por padrão (comportamento nativo).

### Usando o partial `shared/_modal`

```erb
<%# Abre o modal — coloque o botão em qualquer lugar da view %>
<button type="button" onclick="<%= open_modal('meu-modal') %>"
        class="btn-primary cursor-pointer">
  Abrir modal
</button>

<%# Renderiza o modal — coloque ao final da view %>
<%= render layout: "shared/modal", locals: { id: "meu-modal", title: "Título do modal" } do %>

  <%# Conteúdo livre: form, texto, lista, etc. %>
  <p class="text-sm mb-5" style="color: #8D6E63">Descrição do que vai acontecer.</p>

  <%# Rodapé padrão: outline à esquerda, preenchido à direita %>
  <div class="flex gap-3">
    <button type="button" onclick="this.closest('dialog').close()"
            class="btn-outline flex-1 cursor-pointer">
      Cancelar
    </button>
    <%= button_to "Confirmar", acao_path, method: :post,
          class: "btn-primary flex-1 cursor-pointer" %>
  </div>

<% end %>
```

### Modal com formulário interno

```erb
<%= render layout: "shared/modal", locals: { id: "form-modal", title: "Adicionar item" } do %>
  <%= form_with url: itens_path, method: :post, data: { turbo: false },
        class: "flex flex-col gap-4" do %>
    <div>
      <label class="label">Nome</label>
      <input type="text" name="nome" class="input-field" placeholder="Nome" required>
    </div>
    <%= render "shared/modal_actions", label: "Salvar" %>
  <% end %>
<% end %>
```

> O partial `shared/_modal_actions` já inclui botão Cancelar (`btn-outline flex-1`) e
> botão Salvar (`btn-primary flex-1`) no padrão correto — use sempre que o modal tiver formulário.

### Modal de confirmação / destrutivo

```erb
<%= render layout: "shared/modal", locals: { id: "delete-modal", title: "Excluir item?" } do %>
  <p class="text-center text-sm mb-5" style="color: #8D6E63">
    Essa ação não pode ser desfeita.
  </p>
  <div class="flex gap-3">
    <button type="button" onclick="this.closest('dialog').close()"
            class="btn-outline flex-1 cursor-pointer">
      Cancelar
    </button>
    <%= button_to "Excluir", item_path(@item), method: :delete,
          class: "btn-danger-filled flex-1" %>
  </div>
<% end %>
```

### O que o partial `shared/_modal` entrega

- `<dialog id="..." onclick="if(event.target===this)this.close()">` com padding e header prontos
- Título (`font-medium text-sm`, cor primária) + botão X de fechar
- Conteúdo via `yield`
- **Sem posicionamento inline** — o centering é 100% CSS global via `position: fixed; inset: 0; margin: auto; height: fit-content`

### ⚠️ Onde renderizar o `<dialog>`

Renderize sempre **ao final da view**. Evite colocar `<dialog>` dentro de elementos que tenham
`transform`, `filter`, `perspective` ou `will-change: transform` — esses contextos criam um novo
"containing block" para `position: fixed` e quebram o centering automático.

`overflow: hidden` em ancestrais **não** afeta `position: fixed` por spec; não há necessidade
de mover modais por causa disso.

---

## 3 · Componentes prontos para reutilizar

Estes partials já existem no projeto. **Use sempre que possível**, não recrie.

| Partial | Uso |
|---|---|
| `shared/back_button` | `<%= render "shared/back_button", path: caminho_path %>` |
| `shared/avatar` | `<%= render "shared/avatar", user: @user, size: "md" %>` |
| `shared/flash` | Renderizado automaticamente no layout |
| `shared/form_errors` | `<%= render "shared/form_errors", object: @recurso %>` |
| `shared/slot_card` | `<%= render "shared/slot_card", availability: av %>` |
| `shared/logo` | `<%= render "shared/logo", size: "lg" %>` |

---

## 4 · Classes utilitárias do projeto

Definidas em `app/assets/tailwind/application.css`. Use-as em vez de reescrever inline.

| Classe | O que faz |
|---|---|
| `.btn-primary` | Botão marrom pill com texto branco |
| `.btn-outline` | Botão com borda marrom pill, texto marrom |
| `.btn-cta` | CTA principal **largura total** (pill marrom, `block w-full`) — use em "Confirmar →", "Gerar Pix →", etc. |
| `.btn-danger` | Botão outline vermelho (destructive leve) |
| `.btn-danger-filled` | Botão **sólido vermelho** — use em modais de confirmar exclusão (par com `.btn-outline`) |
| `.btn-sm-primary` / `.btn-sm-outline` | Versões menores (headers de admin: "+ Adicionar", "Editar") |
| `.btn-xs-outline` / `.btn-xs-danger` | Versões mínimas (botões inline em linhas de listagem) |
| `.input-field` | Input retangular com borda (use só em formulários antigos) |
| `.label` | Label de input (texto pequeno marrom) |
| `.card` | Card branco principal (rounded-3xl + shadow-lg) |
| `.card-sm` / `.card-md` | Cards menores |
| `.card-link` | Card branco **clicável** (`block bg-white rounded-2xl shadow-sm p-4 hover:shadow-md ...`) — use em `link_to`/`button_to` de listagens |
| `.badge-success` / `.badge-warning` / `.badge-danger` / `.badge-neutral` | Badges de status |
| `.form-errors` | Caixa de erros de formulário |
| `.empty-state` | Estado vazio (texto centralizado) |

**Helpers de status (Ruby — `ApplicationHelper`):**

| Helper | Retorno | Uso |
|---|---|---|
| `booking_group_status_badge(status)` | Classe `.badge-*` | `<span class="<%= booking_group_status_badge(group.status) %>">` |
| `payment_status_badge(status)` | Classe `.badge-*` | `<span class="<%= payment_status_badge(p.status) %>">` |

Nunca escreva o badge inline com `style="background-color: ...; color: ..."` — sempre via helper.

---

## 5 · Cores rápidas (cole quando precisar de inline)

```
Texto principal escuro    #3E2723
Texto título marrom       #5D4037
Texto secundário          #8D6E63
Fundo creme               #fef8e1
Slot selecionado          #C9B8A8
Borda de input            #E0E0E0
Sucesso (verde)           #388E3C
Sucesso bg                #E8F5E9
Erro/destructive          #d4183d
Pix                       #32BCAD
```

---

## 6 · Checklist antes de finalizar uma tela nova

Antes de fechar um PR ou commit:

- [ ] Container raiz vem do layout (não duplique `max-w-md`)
- [ ] Tem `<% content_for :title, "..." %>` no topo
- [ ] Tem `<%= render "shared/back_button", path: ... %>` se for tela interna
- [ ] Tem `<h1>` marrom claro
- [ ] Cards usam `rounded-2xl` ou `rounded-3xl` (nunca `rounded-md`/`rounded-lg`)
- [ ] Botões usam `rounded-full` ou classes `.btn-*`
- [ ] Nenhuma classe `text-blue-*`, `bg-blue-*`, `text-gray-900`
- [ ] Telas de detalhe (show): todo conteúdo dentro de cards `bg-white` — nada solto sobre o fundo creme
- [ ] Inputs em formulário usam padrão "card branco com input transparente"
- [ ] Status enums renderizados via `t("modelo.status.#{obj.status}")` (i18n)
- [ ] Testado em viewport 375px (DevTools mobile)
- [ ] Toda string visível pode ser traduzida via `t(...)` (i18n)

---

## 7 · Erros comuns que devem ser evitados

| Errado | Certo |
|---|---|
| `class="rounded-md"` | `class="rounded-2xl"` |
| `class="bg-gray-100"` | `class="bg-white"` ou `style="background-color: #fef8e1"` |
| `class="text-gray-600"` | `style="color: #8D6E63"` |
| `class="px-4 py-2 bg-blue-500"` em botão | `class="btn-primary"` |
| Botões empilhados (`flex-col`) | Botões lado a lado (`flex gap-3`) com `flex-1` em cada um |
| Cancelar como texto simples | `btn-outline flex-1` — mesmo peso visual que o botão primário |
| Recriar `_back_button` inline | `<%= render "shared/back_button", path: ... %>` |
| `<%= obj.status %>` direto | `<%= t("modelo.status.#{obj.status}") %>` |
| `class: "block card-sm ..."` em `link_to` | `class: "block bg-white rounded-2xl shadow-sm p-4 ..."` — expandir sempre em elementos clicáveis |
| `class="btn-primary w-full block"` em CTA de tela | `class="block w-full py-3 rounded-full text-white text-sm font-medium text-center" style="background-color: #5D4037"` — mesmo visual do botão "Confirmar" |
| Conteúdo de show solto sobre o fundo creme | Sempre dentro de `<div class="bg-white rounded-3xl shadow-lg p-6 mb-4">` |
| Lista de itens com `divide-y` dentro de um card único | Cada item como card individual `bg-white rounded-2xl shadow-sm p-4` + card separado para o total |
| `font-semibold` ou `font-bold` em qualquer texto | `font-medium` — peso padrão de toda a tipografia VDC |
| `number_with_precision(valor / 100.0, ...)` | `money(valor_cents)` — usar o helper do projeto |
| `<h1 class="text-3xl">` | `<h1 class="text-2xl font-medium">` |
| Form sem `flex flex-col gap-3` | Sempre usar `gap-3` entre campos |

---

## 8 · Quando criar uma classe utilitária nova

Só crie uma classe nova em `application.css` se:

1. O padrão visual se repete em **3+ lugares**
2. E não cabe em uma classe Tailwind existente
3. E não pode ser um partial (formato visual puro, não conteúdo)

Em vez de criar classes, prefira:
- **Partials** para blocos com conteúdo (cards de listagem, headers complexos)
- **Tailwind inline** para customização pontual
- **Inline `style`** quando precisar de hex específico da paleta

---

## 9 · Exemplo completo: criar tela "Minhas notificações"

Para ilustrar como aplicar tudo junto:

```erb
<% content_for :title, "Minhas notificações" %>

<%= render "shared/back_button", path: perfil_path %>

<h1 class="text-2xl font-bold mb-6" style="color: #3E2723">Notificações</h1>

<% if @notificacoes.empty? %>
  <div class="empty-state">
    <p>Você não tem notificações.</p>
  </div>
<% else %>
  <div class="flex flex-col gap-3">
    <% @notificacoes.each do |n| %>
      <div class="bg-white rounded-2xl shadow-sm p-4">
        <div class="flex items-start justify-between gap-3">
          <div class="flex-1">
            <div class="text-sm font-medium" style="color: #3E2723"><%= n.titulo %></div>
            <div class="text-xs mt-1" style="color: #8D6E63"><%= n.mensagem %></div>
          </div>
          <span class="text-xs" style="color: #8D6E63">
            <%= l(n.created_at, format: :short) %>
          </span>
        </div>
      </div>
    <% end %>
  </div>
<% end %>
```

Pronto — segue todas as convenções, é mobile-first, sem azul, partials reaproveitados.

---

*Atualizar este documento se uma nova convenção surgir. Não duplicar conteúdo do [[DESIGN_SYSTEM]] — referenciar.*
