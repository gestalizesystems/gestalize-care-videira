# Videira Dental — Instruções para Claude Code

Este arquivo é carregado automaticamente em toda sessão neste projeto.
Mantenha-o curto e prático — instruções aqui são **sempre** seguidas.

---

## Regra principal: Design System

**Antes de criar ou modificar qualquer view (`*.html.erb`), modal, partial ou estilo:**

1. Consulte `docs/03_design/TEMPLATE_TELA_E_MODAL.md` — ele tem esqueletos prontos para tela e modal, classes utilitárias e checklist.
2. Consulte `docs/03_design/DESIGN_SYSTEM.md` quando precisar de detalhes de tokens, cores ou componentes.
3. Verifique se a mudança que vai fazer está **em conformidade** com o template:
   - Cards com `rounded-2xl`/`rounded-3xl` (nunca `rounded-md`/`rounded-lg`)
   - Botões com `rounded-full` ou classes `.btn-*`
   - Sem `text-blue-*`, `bg-blue-*`, `text-gray-*` do Tailwind default
   - Paleta VDC apenas (marrom `#5D4037`, creme `#fef8e1`, secundário `#8D6E63`, etc.)
   - Inputs em formulários no padrão "card branco com input transparente"
   - Status enums via `t("modelo.status.#{obj.status}")`
4. Se uma convenção nova surgir durante a mudança (algo que se repete ou padroniza algo novo), **atualize o template** `TEMPLATE_TELA_E_MODAL.md` no mesmo commit.
5. Se a mudança **divergir intencionalmente** do template, explique o porquê antes de aplicar.

---

## Fluxo ao receber pedido de mudança visual

Sempre nessa ordem:

1. **Ler o template** — confirma o padrão atual.
2. **Aplicar a mudança** seguindo o esqueleto correspondente (tela/modal/formulário/listagem).
3. **Rodar o checklist final** do template mentalmente antes de finalizar.
4. **Se identificou um padrão novo** (algo que pode se repetir), atualizar o template.

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
- MercadoPago para pagamentos (Pix)
- PostgreSQL

---

## Documentação completa

Ver `docs/00_INDEX.md` para mapa de toda a documentação do projeto.
