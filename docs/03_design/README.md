# Design System — Videira Dental

> **Comece aqui** ao criar ou modificar qualquer tela, partial, modal ou estilo.

---

## Estrutura desta pasta

| Arquivo | Quando consultar |
|---|---|
| [`TEMPLATE_TELA_E_MODAL.md`](TEMPLATE_TELA_E_MODAL.md) | **Sempre** ao criar uma view nova (`*.html.erb`) ou modal. Tem esqueletos prontos para copiar. |
| [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) | Referência de tokens (cores, raio, fonte), classes utilitárias `.btn-*`, `.card-*`, `.badge-*` e helpers Ruby. |
| [`CATALOGO_TELAS.md`](CATALOGO_TELAS.md) | Catálogo das telas existentes com o padrão (Variação A/B/C) e helpers que cada uma usa — útil para encontrar um exemplo equivalente ao que você vai construir. |
| [`ARCHIVE_RESTYLING.md`](ARCHIVE_RESTYLING.md) | Histórico do restyling inicial (2026-05). **Não use mais como guia** — está aqui só por contexto. |

---

## Fluxo recomendado para uma nova tela

1. **Identificar o tipo** de tela (formulário / listagem / detalhe / dashboard).
2. **Procurar uma tela similar** em [`CATALOGO_TELAS.md`](CATALOGO_TELAS.md) e abrir a view para usar como base.
3. **Copiar o esqueleto** correspondente do [`TEMPLATE_TELA_E_MODAL.md`](TEMPLATE_TELA_E_MODAL.md) (Variação A, B ou C).
4. **Usar classes utilitárias e helpers** documentados em [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) — nunca recriar inline.
5. **Rodar o checklist** final do template antes de fechar o PR.
6. **Atualizar o catálogo** ([`CATALOGO_TELAS.md`](CATALOGO_TELAS.md)) com a nova tela.
7. **Se uma convenção nova surgiu** (padrão que se repete), atualizar `TEMPLATE_TELA_E_MODAL.md` ou criar classe utilitária em `app/assets/tailwind/application.css`.

---

## Regras invioláveis (resumo)

- **Mobile-first**, container `max-w-md mx-auto px-4 py-6` vindo do layout.
- **Cards brancos**: `rounded-2xl` (secundário) ou `rounded-3xl` (principal). Nunca `rounded-md`/`rounded-lg`/`rounded-xl`.
- **Botões** com `rounded-full` ou classes `.btn-*`.
- **Tipografia** sempre `font-medium`. Nunca `font-semibold` ou `font-bold`.
- **Sem Tailwind default colors**: nada de `text-blue-*`, `bg-blue-*`, `text-gray-*`, `hover:bg-gray-*`. Use paleta VDC ou inline `style`.
- **Status enums** sempre via `t("modelo.status.#{obj.status}")` + helper `*_status_badge(...)` para a classe CSS.
- **Inputs em mobile** com `font-size: 16px` (já garantido pelo CSS global).

---

## Comandos úteis de auditoria

```bash
# Detectar violações de tipografia
grep -rn 'font-semibold\|font-bold' app/views/ --include="*.erb"

# Detectar Tailwind default colors
grep -rn 'text-blue-\|bg-blue-\|text-gray-\|bg-gray-\|hover:bg-gray-' app/views/ --include="*.erb"

# Detectar border-radius fora do padrão
grep -rn 'rounded-md\|rounded-lg\|rounded-xl\|divide-y' app/views/ --include="*.erb"

# Detectar status enums sem i18n
grep -rn '<%= [a-z_@.]*\.status %>' app/views/ --include="*.erb"
```
