# Videira Dental — Instruções para Claude Code

Este arquivo é carregado automaticamente em toda sessão neste projeto.
Mantenha-o curto e prático — instruções aqui são **sempre** seguidas.

---

## Regra principal: Design System

**Antes de criar ou modificar qualquer view (`*.html.erb`), modal, partial ou estilo:**

1. Abrir `docs/03_design/README.md` para confirmar o fluxo recomendado.
2. Consultar `docs/03_design/CATALOGO_TELAS.md` para encontrar uma tela equivalente já existente — abrir essa view como ponto de partida.
3. Copiar o esqueleto correspondente (Variação A/B/C/D/E) de `docs/03_design/TEMPLATE_TELA_E_MODAL.md`.
4. Usar classes utilitárias e helpers documentados em `docs/03_design/DESIGN_SYSTEM.md` — **nunca recriar inline** o que já existe como classe `.btn-*` / `.card-*` / `.badge-*` / `.btn-cta` / `.card-link` ou como helper Ruby (`booking_group_status_badge`, `payment_status_badge`, `money`, `open_modal`).
5. Validar a conformidade da mudança:
   - Cards com `rounded-2xl`/`rounded-3xl` (nunca `rounded-md`/`rounded-lg`/`rounded-xl`)
   - Botões com `rounded-full` ou classes `.btn-*`
   - Tipografia sempre `font-medium` (nunca `font-semibold`/`font-bold`)
   - Sem `text-blue-*`, `bg-blue-*`, `text-gray-*`, `hover:bg-gray-*`, `hover:bg-red-*` do Tailwind default
   - Paleta VDC apenas (marrom `#5D4037`, creme `#fef8e1`, secundário `#8D6E63`, etc.)
   - Inputs em formulários no padrão "card branco com input transparente" ou `.input-field`
   - Status enums via `t("modelo.status.#{obj.status}")` + helper `*_status_badge(...)` para a classe
6. **Após criar uma tela nova**, adicionar uma linha em `CATALOGO_TELAS.md` com a view, o tipo de padrão e observações.
7. Se uma convenção nova surgir (padrão que se repete em 3+ lugares), **adicionar classe utilitária** em `app/assets/tailwind/application.css` e **atualizar `DESIGN_SYSTEM.md` e `TEMPLATE_TELA_E_MODAL.md`** no mesmo commit.
8. Se a mudança **divergir intencionalmente** do template, explique o porquê antes de aplicar.

---

## Mapa de docs/03_design/

| Quando | Abrir |
|---|---|
| Comecei uma tarefa nova de UI | `README.md` |
| Vou criar/alterar uma tela | `TEMPLATE_TELA_E_MODAL.md` |
| Procuro um exemplo equivalente | `CATALOGO_TELAS.md` |
| Esqueci uma classe/cor/helper | `DESIGN_SYSTEM.md` |
| Curiosidade histórica | `ARCHIVE_RESTYLING.md` (não é guia) |

---

## Fluxo ao receber pedido de mudança visual

Sempre nessa ordem:

1. **Identificar o tipo da tela** (formulário / listagem / detalhe / dashboard / página estática).
2. **Procurar tela similar** em `CATALOGO_TELAS.md` e usar como base.
3. **Aplicar a mudança** seguindo o esqueleto correspondente do `TEMPLATE_TELA_E_MODAL.md`.
4. **Usar classes/helpers existentes** — buscar primeiro em `DESIGN_SYSTEM.md` antes de escrever Tailwind ou `style` inline.
5. **Rodar o checklist final** do template mentalmente antes de finalizar.
6. **Atualizar `CATALOGO_TELAS.md`** se a tela é nova.
7. **Se identificou um padrão novo** (repete 3+ vezes), extrair em `application.css` e atualizar os docs.

---

## i18n

Toda string visível no UI deve usar `t(...)`. Status enums seguem o padrão:
`t("modelo.status.#{obj.status}")`. Arquivo: `config/locales/pt-BR.yml`.

---

## Convenções de código gerais

- **Não criar testes, migrations ou refactors** que não foram pedidos.
- **Não adicionar comentários** que apenas descrevem o que o código faz.
- **Editar arquivos existentes** antes de criar novos.
- **Não criar arquivos de documentação** sem pedido explícito (exceção: atualizar docs existentes quando relevante).

---

## Stack

- Ruby on Rails + ERB + Tailwind CSS v4
- Stimulus para JS
- Devise para autenticação
- InfinitePay Checkout para pagamentos (Pix, checkout hospedado)
- PostgreSQL

---

## Documentação completa

Ver `docs/00_INDEX.md` para mapa de toda a documentação do projeto.
