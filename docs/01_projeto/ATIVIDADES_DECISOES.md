# Atividades e Decisões — Auditoria docs × código (2026-06-10/11)

> Registro do que foi feito na auditoria completa de documentação/arquitetura,
> **por que** cada decisão foi tomada, e as pendências técnicas encontradas no caminho.
> Formato: decisão → contexto → motivo → consequência (ADR leve).
> Em 2026-06-11 os docs foram atualizados também para a feature de **pagamento de diferença** na troca de turno (payments passou a 1—N por grupo).

---

## 1. O que motivou

Os documentos de `docs/01_projeto/` e `docs/02_arquitetura/` datavam de 2026-05-09 e descreviam um sistema que não existe mais nesses termos: MercadoPago com QR Pix inline, model `Room`, money decimal, enums integer, controllers `home/cart/users`. O código real (auditado em 2026-06-10) usa InfinitePay Checkout, `Service` + `Availability` direto na clínica, centavos, enums string com check constraint e namespaces `auth/scheduling/payments/users/admin`. Documentação que mente é pior que documentação que falta.

---

## 2. Atividades realizadas

| # | Atividade | Arquivo |
|---|---|---|
| 1 | Corrigido o gateway no stack (MercadoPago → InfinitePay) | `CLAUDE.md` |
| 2 | Funcionalidades atualizadas: recarga de crédito, reserva manual e troca de turno no admin | `README.md` |
| 3 | Reescrito com a estrutura real de pastas, fluxos, segurança do webhook e testes | `docs/02_arquitetura/ARQUITETURA.md` |
| 4 | Reescrito espelhando `db/schema.rb` (11 tabelas reais, incl. `services`, `credits`, `credit_purchases`) | `docs/02_arquitetura/BANCO_DE_DADOS.md` |
| 5 | Reescrito com 6 módulos (novo: Créditos/Carteira) e fluxos InfinitePay | `docs/02_arquitetura/MODULOS.md` |
| 6 | Banner de status com tabela de divergências spec × implementação | `docs/01_projeto/FONTE_DA_VERDADE.md` |
| 7 | Marcado como histórico, apontando para os docs atuais | `docs/01_projeto/CONTEXT.md` |
| 8 | Transformado em roadmap de carreira **Júnior → Tech Senior** ancorado no projeto | `docs/01_projeto/ROADMAP.md` |
| 9 | Marcado como arquivado (MVP concluído; conteúdo histórico preservado) | `docs/01_projeto/ROADMAP_TECNICO.md` |
| 10 | Adicionada a tela Carteira ao catálogo | `docs/03_design/CATALOGO_TELAS.md` |
| 11 | Índice atualizado (novos papéis dos docs + este documento) | `docs/00_INDEX.md` |
| 12 | Corrigida a nota sobre Selenium (system specs usam só rack_test) | `docs/01_projeto/ATIVIDADES.md` |
| 13 | Criado este documento | `docs/01_projeto/ATIVIDADES_DECISOES.md` |

---

## 3. Decisões e motivos

### D1 — Reescrever ARQUITETURA/BANCO_DE_DADOS/MODULOS em vez de remendar
**Contexto:** os três docs estavam errados em quase toda seção (estrutura de pastas, rotas, schema, gateway).
**Motivo:** remendo em documento 90% desatualizado gera frankenstein — o leitor não sabe em qual parágrafo confiar. Reescrever a partir do código garante que 100% do conteúdo foi conferido. Os docs novos são mais curtos de propósito: documento curto e certo é mantido; documento longo e detalhado demais apodrece (foi exatamente o que aconteceu com as versões de maio).
**Consequência:** perdeu-se o detalhamento "tutorial" dos docs antigos (migrations completas, edge case tables extensas). O que tinha valor histórico continua no git e no `ROADMAP_TECNICO.md` arquivado.

### D2 — FONTE_DA_VERDADE ganha banner de divergências; CONTEXT vira histórico
**Contexto:** ambos se declaravam "fonte da verdade", mas descrevem a spec de maio.
**Motivo:** a FONTE_DA_VERDADE continua válida como **visão de produto** (o que o sistema é e não é) — reescrevê-la apagaria a spec original, que tem valor de referência. Um banner com a tabela de divergências resolve: o leitor sabe imediatamente o que mudou e onde está a verdade atual. O CONTEXT já era redundante (a própria FONTE_DA_VERDADE diz "substitui o CONTEXT.md"), então foi rebaixado a histórico em vez de mantido como segunda fonte concorrente.
**Consequência:** passa a haver hierarquia clara: código > ARQUITETURA/BANCO_DE_DADOS/MODULOS (estado atual) > FONTE_DA_VERDADE (visão de produto) > CONTEXT/ROADMAP_TECNICO (histórico).

### D3 — ROADMAP.md vira roadmap de carreira Júnior → Tech Senior
**Contexto:** pedido explícito do usuário; o roadmap de produto original estava 100% concluído e obsoleto (fases de `rails new`, MercadoPago).
**Motivo:** um roadmap de carreira genérico ("estude Docker, estude testes") não gruda. O formato escolhido ancora cada competência em **gaps reais deste projeto** (webhook sem validação de valor, recargas sem expiração, system specs sem JS, ausência de observabilidade/backup testado) — assim o estudo produz melhorias reais no portfólio ao mesmo tempo. Cada fase tem critério de conclusão verificável, porque "achar que aprendeu" é a armadilha clássica do autodidata.
**Consequência:** o roadmap de produto deixa de existir como doc ativo; pendências de produto vivem em `ATIVIDADES.md` (histórico) e na seção 4 abaixo.

### D4 — ROADMAP_TECNICO arquivado em vez de deletado
**Motivo:** registra como o MVP foi sequenciado e os prompts usados — material didático e histórico de decisão. Deletar apagaria contexto; manter sem aviso enganaria. Banner de arquivamento é o meio-termo.

### D5 — Docs novos registram dívidas conhecidas no próprio corpo
**Motivo:** prática senior: documentação que esconde as limitações gera falsa confiança. `ARQUITETURA.md §6` (webhook), `BANCO_DE_DADOS.md §5` (schema) e `MODULOS.md §4` (recargas) apontam explicitamente o que falta, com link para o roadmap.

---

## 4. Pendências técnicas encontradas na auditoria

Achados de **código** (não de docs) descobertos ao conferir os fluxos. Não foram corrigidos nesta auditoria — são insumo das Fases 1–3 do `ROADMAP.md`:

| Prioridade | Achado | Detalhe | Onde |
|---|---|---|---|
| 🔴 Alta | Webhook não valida o valor pago | Os três confirmadores (`PaymentConfirmer`, `CreditPurchaseConfirmer`, `DifferencePaymentConfirmer`) confirmam com qualquer `paid_amount > 0`; nenhum compara com o `amount_cents` esperado nem reconsulta o gateway antes de confirmar | `app/services/*_confirmer.rb`, `app/controllers/payments/webhooks_controller.rb` |
| 🟡 Média | Recargas pendentes nunca expiram | `ExpirePaymentsJob` só varre `Payment`; `CreditPurchase` pendente fica `pending` para sempre (não trava slot, mas suja dados e relatórios) | `app/jobs/expire_payments_job.rb` |
| 🟡 Média | Troca de turno aplica o novo slot antes do pagamento da diferença | `AdminBookingSlotChanger` move a reserva para o turno mais caro imediatamente; se a diferença Pix nunca for paga, a reserva permanece no turno caro com `Payment` pendente (decidir: reverter na expiração ou aceitar como risco operacional do admin) | `app/services/admin_booking_slot_changer.rb` |
| 🟡 Média | `credit_purchases.status` sem check constraint | Única tabela de domínio com status sem constraint — inconsistente com a convenção do schema | migration nova |
| 🟡 Média | System specs não cobrem JS | `spec/support/capybara.rb` usa só `rack_test`; não há `selenium-webdriver` no Gemfile — calendário, carrinho e modais (Stimulus) não têm teste de browser | `Gemfile`, `spec/support/capybara.rb` |
| 🟢 Baixa | Cobertura Pundit desigual | Sem policies para Availability/Service/Credit/etc.; admin depende só de `require_owner!` (funciona, mas vale auditoria de rotas × autorização) | `app/policies/` |
| 🟢 Baixa | Motivo de cancelamento não persiste | `bookings` não tem `cancel_reason`/`cancelled_at` (a spec original previa) — hoje o histórico fica só no PaperTrail | schema |
| 🟢 Baixa | Sem observabilidade | Nenhum error tracking, uptime check ou métrica além de logs — item central da Fase 2 do roadmap | infra |

---

## 5. Como manter este documento

- Decisão arquitetural nova → adicionar entrada na seção 3 (contexto → motivo → consequência), no mesmo commit da mudança.
- Pendência resolvida → mover da tabela da seção 4 para `ATIVIDADES.md` (✅ Concluído) com a data.
- Auditoria docs × código: repetir a cada ciclo grande de features (a deriva de maio→junho mostrou que 1 mês de ritmo intenso já descola os docs).
