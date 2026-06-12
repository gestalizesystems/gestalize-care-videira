# DESIGN_SYSTEM — Videira Dental

> Referência de tokens, classes utilitárias e helpers do projeto.
> Para **esqueletos de tela e modal**, ver [`TEMPLATE_TELA_E_MODAL.md`](TEMPLATE_TELA_E_MODAL.md).
> Para **mapa de telas existentes**, ver [`CATALOGO_TELAS.md`](CATALOGO_TELAS.md).

---

## 1 · Identidade visual

| Item | Valor |
|---|---|
| **Estética** | Warm, orgânica, confiável — tons terrosos com fundo creme |
| **Fonte** | `Prompt` (Google Fonts), pesos 300, 400, 500, 600, 700 — **padrão sempre 500 (`font-medium`)** |
| **Border radius padrão** | `rounded-2xl` (cards secundários), `rounded-3xl` (cards principais), `rounded-full` (botões/badges/pills) |
| **Layout base** | `max-w-md mx-auto px-4 py-6` — mobile-first, máx 448px |
| **Fundo da aplicação** | `#fef8e1` (creme) — definido no `body` em `application.css` |

---

## 2 · Paleta (tokens)

Definida em `app/assets/tailwind/application.css` como CSS variables. Hex inline aceito quando necessário.

| Token | Hex | Uso |
|---|---|---|
| `--color-vdc-background` | `#fef8e1` | Fundo de toda a página |
| `--color-vdc-foreground` | `#3E2723` | Texto principal escuro |
| `--color-vdc-primary` | `#5D4037` | Botões, títulos, ações primárias |
| `--color-vdc-secondary` | `#8D6E63` | Texto secundário, ícones |
| `--color-vdc-accent` | `#C9B8A8` | Slots selecionados, estados ativos |
| `--color-vdc-card` | `#ffffff` | Fundo de cards |
| `--color-vdc-border` | `#E0E0E0` | Bordas de inputs e separadores |
| `--color-vdc-destructive` | `#d4183d` | Erros, ações destrutivas |
| `--color-vdc-success` | `#388E3C` | Confirmações, descontos |
| `--color-vdc-success-bg` | `#E8F5E9` | Fundo de badges de sucesso |
| — | `#32BCAD` | Verde Pix (exclusivo do botão/ícone Pix) |
| — | `#FFF9C4` / `#F57F17` | Badge warning (bg/texto) |
| — | `#FFEBEE` | Badge danger (bg) |
| — | `#F5F5F5` / `#757575` | Badge neutral / estados desabilitados |
| — | `#BDBDBD` | Texto em estados desabilitados |

**Para colar em inline `style`:**

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

## 3 · Classes utilitárias do projeto

Definidas em `app/assets/tailwind/application.css` (camada `@layer components`). **Use estas classes em vez de reescrever inline.**

### Cards

| Classe | Equivalente Tailwind | Quando usar |
|---|---|---|
| `.card` | `bg-white rounded-3xl shadow-lg p-6` | Card principal de show, formulário grande |
| `.card-md` | `bg-white rounded-2xl shadow-sm p-5` | Card secundário com mais respiro |
| `.card-sm` | `bg-white rounded-2xl shadow-sm p-4` | Card de listagem, item de feed |
| `.card-link` | `.card-sm` + `hover:shadow-md transition-all active:scale-[0.98]` + `block` | **Sempre** em `link_to`/`button_to` que envolve um card de listagem |

### Botões

| Classe | Quando usar |
|---|---|
| `.btn-primary` | Botão marrom pill — par com `.btn-outline` em formulários |
| `.btn-outline` | Botão outline marrom — par com `.btn-primary` |
| `.btn-cta` | **CTA full-width** (pill marrom largura total) — "Confirmar →", "Gerar Pix", etc. |
| `.btn-danger` | Botão **outline** vermelho — destrutivo leve |
| `.btn-danger-filled` | Botão **sólido** vermelho — confirmar exclusão em modais (par com `.btn-outline`) |
| `.btn-sm-primary` / `.btn-sm-outline` | Versões menores — headers de admin ("+ Adicionar", "Editar") |
| `.btn-xs-outline` / `.btn-xs-danger` | Versões mínimas — botões inline em linhas de listagem |

### Inputs e labels

| Classe | Quando usar |
|---|---|
| `.input-field` | Input retangular com borda — use em formulários "labelados" |
| `.label` | Label de input acima do campo |

### Badges de status

**Sempre** via helpers `booking_group_status_badge(...)` ou `payment_status_badge(...)` — nunca inline.

| Classe | Cor |
|---|---|
| `.badge-success` | Verde — confirmado, ativo, pago, disponível |
| `.badge-warning` | Amarelo — pendente, aguardando |
| `.badge-danger` | Vermelho — falha, expirado |
| `.badge-neutral` | Cinza — cancelado, inativo, usado |

### Outros

| Classe | Uso |
|---|---|
| `.form-errors` | Caixa de erros de formulário |
| `.empty-state` | Estado vazio (texto centralizado, padding generoso) |
| `.text-vdc-primary` / `.text-vdc-secondary` / `.text-vdc-foreground` | Helpers de cor da paleta (alternativa a inline `style`) |
| `.bg-vdc-background` / `.bg-vdc-primary` / `.bg-vdc-accent` / `.bg-vdc-card` | Helpers de bg da paleta |
| `.border-vdc-default` | Borda `#E0E0E0` |

---

## 4 · Helpers Ruby (`ApplicationHelper`)

| Helper | Retorno | Uso |
|---|---|---|
| `booking_group_status_badge(status)` | String `"badge-*"` | `<span class="<%= booking_group_status_badge(group.status) %>">` |
| `payment_status_badge(status)` | String `"badge-*"` | `<span class="<%= payment_status_badge(p.status) %>">` |
| `money(cents)` | String `"123,45"` | Sempre para valores monetários — nunca usar `number_with_precision(... / 100.0)` direto |
| `open_modal(id)` | String JS para `onclick` | `onclick="<%= open_modal('my-dialog') %>"` em botões |

Combine com `t("modelo.status.#{obj.status}")` para o texto traduzido:

```erb
<span class="<%= payment_status_badge(p.status) %>">
  <%= t("payment.status.#{p.status}") %>
</span>
```

---

## 5 · Partials compartilhados (`app/views/shared/`)

| Partial | Uso |
|---|---|
| `shared/back_button` | `<%= render "shared/back_button", path: caminho_path %>` no topo de telas internas |
| `shared/avatar` | `<%= render "shared/avatar", user: @user, size: "md" %>` — tamanhos `sm`/`md`/`lg` |
| `shared/flash` | Renderizado automaticamente no layout |
| `shared/form_errors` | `<%= render "shared/form_errors", object: @recurso %>` antes do form |
| `shared/slot_card` | `<%= render "shared/slot_card", availability: av %>` para slot de horário |
| `shared/logo` | `<%= render "shared/logo", size: "lg" %>` |
| `shared/modal` | `<%= render layout: "shared/modal", locals: { id: "...", title: "..." } do %>...<% end %>` |
| `shared/modal_actions` | Rodapé de botões em modal: `<%= render "shared/modal_actions", label: "Salvar" %>` |
| `shared/cart_summary` | Sticky cart na home (Turbo Frame) |

---

## 6 · Tipografia

A `application.css` define os defaults:

| Elemento | Tamanho | Peso |
|---|---|---|
| `h1` | 1.5rem (`text-2xl`) | 500 (`font-medium`) |
| `h2` | 1.25rem (`text-xl`) | 500 (`font-medium`) |
| `h3` | 1.125rem (`text-lg`) | 500 (`font-medium`) |
| `h4` | 1rem (`text-base`) | 500 (`font-medium`) |
| `button` | 1rem | 500 (`font-medium`) |
| `input, select, textarea` | **16px** (anti-zoom iOS) | 400 (`font-normal`) |

> **Regra:** nunca use `font-semibold` ou `font-bold`. O peso padrão de toda a tipografia VDC é `font-medium`.

---

## 7 · i18n

Toda string visível no UI usa `t(...)`. Status enums seguem `t("modelo.status.#{obj.status}")`.

**Arquivo:** `config/locales/pt-BR.yml`. Chaves de status já cadastradas:

- `booking_group.status.{pending,confirmed,cancelled,expired}`
- `booking.status.{pending,confirmed,cancelled}`
- `payment.status.{pending,paid,failed,cancelled,expired}`
- `availability.status.{available,booked,cancelled,blocked}`

---

## 8 · Quando criar uma classe utilitária nova

Crie em `application.css` (`@layer components`) **somente** se:

1. O padrão visual se repete em **3+ lugares**;
2. Não cabe em uma classe Tailwind existente;
3. Não pode ser um partial (é formato visual puro, não conteúdo).

Senão, prefira:
- **Partials** para blocos com conteúdo (cards de listagem complexos, headers).
- **Tailwind utility** para customização pontual.
- **Inline `style`** para hex específico da paleta.

Depois de adicionar uma classe nova, **atualize este documento e o template**.
