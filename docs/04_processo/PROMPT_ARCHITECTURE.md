# PROMPT_ARCHITECTURE.md

> **Arquitetura de documentação e prompts para projetos com Claude Code.**
> Template independente de stack, derivado da abordagem que produziu o Videira Dental Clinic (VDC) e refinado com lições reais da implementação.
> Tempo de leitura: ~20 min. Aplicação em projeto novo: ~6-10h de redação antes da primeira linha de código.

---

## Sumário

0. [Antes de começar — validação do produto](#0-antes-de-começar--validação-do-produto)
1. [Por que esse método funciona](#1-por-que-esse-método-funciona)
2. [Os documentos da fonte da verdade](#2-os-documentos-da-fonte-da-verdade)
3. [Templates preenchíveis](#3-templates-preenchíveis)
4. [Persistência de memória — as 4 camadas](#4-persistência-de-memória--as-4-camadas)
5. [Workflow com Claude Code](#5-workflow-com-claude-code)
6. [Ferramentas do Claude Code que mudam o jogo](#6-ferramentas-do-claude-code-que-mudam-o-jogo)
7. [Rituais de sessão](#7-rituais-de-sessão)
8. [Lições aprendidas (com exemplos reais do VDC)](#8-lições-aprendidas-com-exemplos-reais-do-vdc)
9. [Checklist de prontidão](#9-checklist-de-prontidão)
10. [Prompt engineering específico para Claude Code](#10-prompt-engineering-específico-para-claude-code)
11. [Troubleshooting comum](#11-troubleshooting-comum)

---

## 0. Antes de começar — validação do produto

Documentar um produto que você não entende é desperdício. Antes de abrir o primeiro `.md`, responda **por escrito** (em qualquer rascunho, não precisa ser formal):

1. **Em uma frase, quem é o usuário e qual problema ele resolve?**
2. **Como ele resolve esse problema hoje (sem o seu sistema)?**
3. **Qual a métrica de sucesso?** (vendas, tempo economizado, erros evitados)
4. **O que faz esse problema valer a pena resolver com software?**
5. **Qual é a versão **mínima** que valida a hipótese?**

Se você não consegue responder, **não comece a documentar** — você ainda está na fase de descoberta. Use ferramentas de pesquisa (entrevistas, planilhas, Notion) primeiro.

> **Sintoma de que pulou esta etapa:** o `FONTE_DA_VERDADE.md` cresce indefinidamente porque cada decisão depende de uma anterior que nunca foi tomada.

---

## 1. Por que esse método funciona

O Claude Code não é um chat genérico. Ele lê e escreve arquivos, executa comandos, navega o repositório e mantém contexto entre tarefas. Isso muda como você trabalha com ele:

| Sem documentação prévia | Com documentação prévia |
|---|---|
| Cada prompt re-explica o projeto | Cada prompt referencia uma seção curta de um doc canônico |
| Claude inventa regras quando há lacuna | Claude consulta o doc; se a resposta não existe, **pergunta** |
| Decisões mudam entre sessões | Decisões são fixadas e versionadas em arquivos |
| Tarefas são implementadas fora de ordem | O ROADMAP impõe a sequência correta |
| Refatorações constantes para alinhar contradições | Contradições são pegas no texto, não no código |
| Sessão nova começa do zero | Sessão nova lê os docs e retoma onde parou |

**Três princípios sustentam o método:**

1. **Fonte da verdade única** — contradição entre dois documentos é bug. O documento master vence; corrija o derivado.
2. **Prompts atômicos** — uma tarefa do ROADMAP por prompt, com referência explícita à seção do doc relevante.
3. **Decisão antes de código** — cada "vai usar X ou Y?" é resolvido por escrito antes de gerar arquivos.

**Corolário fundamental:** o trabalho do dev solo deixa de ser **escrever código** e passa a ser **decidir + documentar + revisar**. Claude executa; você orquestra.

---

## 2. Os documentos da fonte da verdade

A ordem de criação importa: cada doc usa decisões dos anteriores.

| # | Documento | Função | Tamanho típico | Obrigatório? |
|---|---|---|---|---|
| 1 | `FONTE_DA_VERDADE.md` | Master. Define produto, stack, regras de negócio, atores, FAQ. | 800-2000 linhas | ✅ |
| 2 | `ARQUITETURA.md` | Camadas, pastas, responsabilidades, comunicação entre camadas. | 400-1000 linhas | ✅ |
| 3 | `BANCO_DE_DADOS.md` | Schema completo, migrations, índices, constraints, ERD. | 300-800 linhas | ✅ se tem persistência |
| 4 | `MODULOS.md` | Mapa funcional dividido em módulos (carrinho, pagamento, auth...). | 200-600 linhas | Recomendado |
| 5 | `ROADMAP_TECNICO.md` | Tarefas em ordem de dependência, **com prompt pronto para IA**. | 500-1500 linhas | ✅ |
| 6 | `DESIGN_SYSTEM.md` | Tokens visuais, componentes UI, tradução Figma → código. | 200-600 linhas | Se tem UI |
| 7 | `CLAUDE.md` | Atalhos para o Claude Code: comandos, convenções, links para docs. | 50-200 linhas | ✅ (raiz do repo) |
| 8 | `ATIVIDADES.md` | Backlog vivo de pendências priorizadas. | Cresce com o projeto | Recomendado |
| 9 | `CONTEXT.md` | Decisões técnicas e armadilhas resolvidas — para retomar de outra máquina. | Cresce com o projeto | Recomendado |

> **Regra:** se o doc N contradiz o doc N-1, o doc N está errado. Conserte o N, não o N-1. O master (`FONTE_DA_VERDADE`) é a autoridade final.

### Hierarquia visual

```
                  FONTE_DA_VERDADE.md
                        (master)
                           │
       ┌───────────────────┼───────────────────┐
       ▼                   ▼                   ▼
 ARQUITETURA.md    BANCO_DE_DADOS.md      MODULOS.md
       │                   │                   │
       └─────────┬─────────┴─────────┬─────────┘
                 ▼                   ▼
         ROADMAP_TECNICO.md   DESIGN_SYSTEM.md
                 │
                 ▼
            CLAUDE.md  (na raiz, lido por toda sessão)
                 │
       ┌─────────┴─────────┐
       ▼                   ▼
 ATIVIDADES.md       CONTEXT.md
 (backlog vivo)      (memória técnica)
```

---

## 3. Templates preenchíveis

Copie cada bloco abaixo para um arquivo `.md` separado e preencha os `{{PLACEHOLDERS}}`. Os comentários `<!-- -->` explicam o que cada seção espera.

### 3.1 Template — `FONTE_DA_VERDADE.md`

```markdown
# {{NOME_DO_PROJETO}} — FONTE_DA_VERDADE.md

> Documento master. Fonte única e canônica.
> Última atualização: {{AAAA-MM-DD}}

---

## 1. Definição do projeto

**{{NOME_DO_PROJETO}}** é {{descrição em 2-3 frases}}.

**É:** {{lista do que o produto faz}}
**Não é:** {{lista do que ele NÃO faz — escopo negativo é tão importante quanto o positivo}}

**Métrica de sucesso:** {{como você mede se o produto funcionou}}

---

## 2. Stack final (validada e congelada)

| Componente | Tecnologia | Por que |
|---|---|---|
| Linguagem / framework | **{{X}}** | {{justificativa em 1 linha}} |
| Frontend | **{{X}}** | {{...}} |
| Banco | **{{X}}** | {{...}} |
| Auth | **{{X}}** | {{...}} |
| Jobs / fila | **{{X}}** | {{...}} |
| Testes | **{{X}}** | {{...}} |
| Deploy | **{{X}}** | {{...}} |

> **Não usar:** {{tecnologias proibidas e por quê — evita Claude propor alternativas populares}}

---

## 3. Atores e roles

| Role | Quem | Como entra na plataforma |
|---|---|---|
| `{{role_1}}` | {{descrição}} | {{cadastro? convite? seed?}} |
| `{{role_2}}` | {{descrição}} | {{...}} |

Default de role no auto-cadastro: `{{role}}`. Mudança de role: {{permitida via X / proibida}}.

---

## 4. Regras de negócio (sem ambiguidade)

<!-- Para CADA entidade do sistema, descreva: validações, transições de estado, constraints, edge cases -->

### 4.1 {{Entidade A}}

- {{regra 1, com restrição numérica explícita}}
- Validação: {{X > Y, em código E em check do banco}}
- Estados: `{{estado_1}}` → `{{estado_2}}` (gatilho: {{evento}})
- Edge case: {{o que acontece quando ...}}
- Concorrência: {{como evitar race condition}}

### 4.2 {{Entidade B}}

{{...}}

---

## 5. ERD canônico

<!-- ASCII ou Mermaid — não precisa ser bonito, precisa ser inequívoco -->

```
{{Entidade A}} 1 ─── N {{Entidade B}}
{{Entidade B}} N ─── 1 {{Entidade C}}
```

---

## 6. Fluxos completos

### 6.1 Happy path: {{Fluxo principal}}

1. {{Ator}} faz {{ação}}.
2. Sistema {{resposta}}.
3. ...

### 6.2 Sad paths

- **Se {{condição}}:** {{comportamento}}.
- **Se {{outra condição}}:** {{outro comportamento}}.
- **Race condition X:** {{como o sistema resolve}}.

---

## 7. Mapa de telas e rotas

| Rota | Quem acessa | O que mostra |
|---|---|---|
| `GET /` | público | {{...}} |
| `POST /{{x}}` | {{role}} | {{...}} |

---

## 8. Convenções de código

- Nomes em {{idioma}} (modelos: {{X}}, variáveis: {{Y}}).
- Comentários: {{quando sim, quando não}}.
- Commits: {{padrão — ex: conventional commits}}.
- Branch naming: {{padrão}}.

---

## 9. Variáveis de ambiente

| Var | Onde usar | Exemplo |
|---|---|---|
| `{{VAR_1}}` | {{...}} | `{{...}}` |

---

## 10. Decisões técnicas registradas

| Data | Decisão | Justificativa | Alternativa rejeitada |
|---|---|---|---|
| {{AAAA-MM-DD}} | {{usar X em vez de Y}} | {{motivo}} | {{Y, porque ...}} |

---

## 11. FAQ — respondido antes que apareça

<!-- Antecipe as perguntas que Claude (ou qualquer dev novo) faria. Responda definitivamente. -->

**P: Por que não usar {{tecnologia popular}}?**
R: {{resposta com critério, não opinião}}.

**P: Como tratar {{caso ambíguo}}?**
R: {{regra única}}.

**P: Posso adicionar feature X que não está documentada?**
R: Não sem alinhamento. Toda feature nova exige update da FONTE_DA_VERDADE primeiro.

---

## 12. Como usar este documento com IA

- **Certo:** "Implemente a tarefa 3.2 do ROADMAP_TECNICO. Regras: FONTE_DA_VERDADE §4.3."
- **Errado:** "Implemente checkout." (sem âncora → Claude inventa)
- Se a resposta não está no doc: **pare, atualize o doc, depois prompte**.
```

### 3.2 Template — `ARQUITETURA.md`

```markdown
# {{NOME_DO_PROJETO}} — ARQUITETURA.md

## 1. Princípios

- {{princípio 1 — ex: "fat models, skinny controllers"}}
- {{princípio 2 — ex: "lógica de negócio em Services, nunca em Controllers"}}
- {{princípio 3 — ex: "multi-tenant desde o MVP via clinic_id em todas as queries"}}

## 2. Estrutura de pastas

```
{{projeto}}/
├── {{camada_1}}/
│   ├── {{...}}
└── {{camada_2}}/
    └── {{...}}
```

## 3. Camadas e responsabilidades

### 3.1 {{Camada A — ex: Models}}
- **Faz:** {{...}}
- **Não faz:** {{...}}
- **Exemplo:** {{snippet curto}}

### 3.2 {{Camada B — ex: Services}}
- **Faz:** {{...}}
- **Não faz:** {{...}}
- **Convenção:** {{ex: toda service herda de ApplicationService e retorna Result}}

## 4. Comunicação entre camadas

```
HTTP request
    ↓
Controller (params, autorização)
    ↓
Service (orquestração + I/O externo)
    ↓
Model (estado + invariantes)
    ↓
DB
```

## 5. Rotas definitivas

```{{ruby|python|ts}}
{{cole as rotas reais aqui — não pseudo-código}}
```

## 6. Layouts / templates base

| Layout | Quando usar | Quem usa |
|---|---|---|
| `{{layout_1}}` | {{...}} | {{...}} |

## 7. Concorrência e estados

- **Race condition X:** evitada com {{lock pessimista / advisory lock / unique index}}
- **Webhook duplicado:** idempotência via {{X}}
- **Job que pode ser re-executado:** garantir {{Y}}

## 8. I18n / localização

- Idioma default: `{{pt-BR}}`
- Estratégia: {{arquivos YAML por idioma / único arquivo / etc}}

## 9. Estrutura de testes

- Framework: {{X}}
- O que **deve** ter teste: {{services, fluxos críticos, policies, transições de estado}}
- O que **não precisa**: {{getters triviais, views estáticas}}
- Boundary: mocks **somente** em sistemas externos (HTTP, mail, push)

## 10. Lint / formatação

- Ferramenta: {{X}}
- Configuração: ver `.{{tool}}rc`
```

### 3.3 Template — `BANCO_DE_DADOS.md`

```markdown
# {{NOME_DO_PROJETO}} — BANCO_DE_DADOS.md

## 1. Convenções globais

- Primary key: `{{uuid|bigint}}` (justificativa: {{...}})
  > **Aviso:** se escolher UUID, **toda** tabela auxiliar (PaperTrail, ActiveStorage, audit logs) deve ser ajustada para `string` em colunas `*_id` polimórficas. Ver §X.
- Timestamps: `created_at`, `updated_at` em todas as tabelas.
- Soft delete: {{sim/não — se sim, qual coluna}}
- Encoding: UTF-8.

## 2. Schema por tabela

### 2.1 `{{nome_da_tabela}}`

| Coluna | Tipo | Null | Default | Constraint |
|---|---|---|---|---|
| `id` | uuid | não | `gen_random_uuid()` | PK |
| `{{coluna}}` | {{tipo}} | {{sim/não}} | {{...}} | {{check, FK, unique}} |

**Índices:**
- `idx_{{tabela}}_{{coluna}}` em `({{coluna}})` — justificativa: {{query frequente X}}

**Check constraints:**
- `{{coluna}} > 0`
- `{{coluna_a}} > {{coluna_b}}`

## 3. Migrations em ordem

| # | Nome | Cria | Depende de |
|---|---|---|---|
| 001 | `EnableExtensions` | extensões pg | — |
| 002 | `CreateUsers` | users | 001 |

## 4. ERD detalhado

```
{{ASCII ou Mermaid completo}}
```

## 5. Seeds

- Dados mínimos para `{{ambiente}}`: {{lista}}
- Localização: `{{caminho/seeds}}`
- Variáveis de ambiente esperadas: `{{ENV_VAR}}`
```

### 3.4 Template — `MODULOS.md`

```markdown
# {{NOME_DO_PROJETO}} — MODULOS.md

## Módulo {{NOME}}

**Atores:** {{quem interage}}
**Endpoints:**
- `{{VERB}} /{{rota}}` — {{descrição}}

**Lógica principal:**
1. {{passo}}
2. {{passo}}

**Edge cases a tratar:**
- {{caso 1 → comportamento esperado}}
- {{caso 2 → comportamento esperado}}

**Dependências de outros módulos:**
- {{Módulo X (para ...)}}

**Métricas:** {{o que monitorar em produção}}

---

## Módulo {{NOME 2}}
{{...}}
```

### 3.5 Template — `ROADMAP_TECNICO.md` (o mais importante)

```markdown
# {{NOME_DO_PROJETO}} — ROADMAP_TECNICO.md

## Como ler

Cada tarefa segue:

```
### N.M Título — Complexidade: B/M/A
**Depende de:** lista de tarefas anteriores
**Por que agora:** justificativa de ordem
**Entregável:** o que existe ao fim
**Prompt para IA:** prompt copiado e colado, sem edição
```

**Complexidade:**
- **B (Baixa):** 30 min – 1h. Configuração, migration simples, view padrão.
- **M (Média):** 1h – 3h. Service novo, fluxo cross-model, integração externa simples.
- **A (Alta):** 3h+. Integração com terceiro real, concorrência, webhook.

---

## FASE 0 — Setup (~Xh)

### 0.1 {{Pré-requisitos do sistema}} — B
**Depende de:** nada
**Por que agora:** sem isto nada roda
**Entregável:** {{...}}
**Prompt para IA:**
```
{{prompt exato — pronto para colar no Claude Code}}
```

---

## FASE 1 — Modelos e auth (~Xh)

### 1.1 {{Migration X}} — B
**Depende de:** 0.4
**Por que agora:** Service que vem em 1.5 precisa do modelo
**Entregável:** migration aplicada + model com validações + 1 spec smoke
**Prompt para IA:**
```
Implemente a tarefa 1.1 do ROADMAP. Schema da tabela: ver BANCO_DE_DADOS.md §2.3.
Regras de validação: ver FONTE_DA_VERDADE §4.2.
NÃO crie controller nem view ainda — apenas migration + model + spec do model.
```

---

## Mapa visual de dependências

```
0.1 → 0.2 → 0.3 → 1.1 → 1.2 ↘
                          → 2.1 → 2.2 → 3.1
                  1.3 ────↗
```

## Estimativa total

{{X-Y horas de implementação}}.
```

### 3.6 Template — `DESIGN_SYSTEM.md`

```markdown
# {{NOME_DO_PROJETO}} — DESIGN_SYSTEM.md

## 1. Tokens

### Cores
| Token | Valor | Uso |
|---|---|---|
| `primary` | `#XXXXXX` | botões principais, links |
| `surface` | `#XXXXXX` | fundos de card |

### Tipografia
| Token | Família | Tamanho | Peso |
|---|---|---|---|
| `heading-xl` | {{...}} | {{...}} | {{...}} |

### Bordas / raios / sombras
{{tabela}}

## 2. Componentes

### 2.1 Botão
**Variantes:** primary, secondary, danger, ghost
**Estados:** default, hover, active, disabled, loading

```{{erb|jsx|vue}}
{{exemplo de uso}}
```

## 3. Tradução Figma → código

| Frame Figma | Componente código | Observações |
|---|---|---|
| `Card / Slot` | `app/views/shared/_slot_card.{{ext}}` | usa token `surface` |
```

### 3.7 Template — `CLAUDE.md` (raiz do repo)

```markdown
# {{NOME_DO_PROJETO}} — CLAUDE.md

> Lido automaticamente por toda sessão do Claude Code.
> Mantenha curto. Detalhes ficam nos docs em `./docs/`.

## Stack
{{linguagem + framework + banco em 1 linha}}

## Documentação canônica
- **Fonte da verdade:** `docs/FONTE_DA_VERDADE.md` (toda regra de negócio)
- **Arquitetura:** `docs/ARQUITETURA.md`
- **Banco:** `docs/BANCO_DE_DADOS.md`
- **Backlog:** `ATIVIDADES.md`
- **Decisões técnicas:** `CONTEXT.md`

## Comandos
```bash
{{instalação}}        # ex: bundle install
{{rodar testes}}      # ex: bundle exec rspec
{{rodar lint}}        # ex: bundle exec rubocop
{{servidor dev}}      # ex: bin/dev
{{migrations}}        # ex: bin/rails db:migrate
```

## Convenções
- Idioma de commits: {{pt-BR | en}}
- Padrão de commits: {{conventional commits}}
- Branch naming: {{feat/, fix/, docs/}}
- Comentários em código: {{só para "porquê" não-óbvio}}

## NUNCA
- Rodar `db:reset` em qualquer ambiente que não seja local
- Commitar `.env` ou credenciais
- Pular hooks de pré-commit com `--no-verify`
- Criar feature sem atualizar a `FONTE_DA_VERDADE.md` primeiro

## Quando em dúvida
Pare e pergunte. Não invente default.
```

### 3.8 Template — `ATIVIDADES.md` (backlog vivo)

```markdown
# Atividades Pendentes — {{NOME_DO_PROJETO}}

> Backlog priorizado. Atualizado conforme tarefas são concluídas.

## Legenda
- 🔴 **Crítico** — bloqueia uso ou quebra produção
- 🟡 **Importante** — feature incompleta mas o app roda
- 🟢 **Melhoria** — qualidade, UX, refactor

---

## 1. {{Categoria}}

### 1.1 🔴 {{Tarefa}}
{{Descrição curta + arquivos a criar/modificar}}

### 1.2 🟡 {{Tarefa}}
{{...}}

---

## Ordem de implementação sugerida
1. {{ID}} — {{razão}}
2. {{ID}} — {{razão}}
```

### 3.9 Template — `CONTEXT.md` (memória técnica)

```markdown
# Contexto técnico — {{NOME_DO_PROJETO}}

> Decisões e armadilhas resolvidas. Lido ao retomar de outra máquina ou em nova sessão.

---

## Decisões de produto
### {{Decisão X (ex: cancelamento → crédito, não reembolso)}}
{{Por que essa decisão e em que situação se aplica}}

---

## Decisões técnicas

### {{Armadilha resolvida X (ex: PaperTrail item_id deve ser string)}}
**Sintoma:** {{como o problema apareceu}}
**Causa:** {{root cause}}
**Solução:** {{o que foi feito + arquivo onde está}}

---

## Convenções de teste
- {{convenção 1}}
- {{convenção 2}}

---

## Como retomar o desenvolvimento
```bash
git clone {{url}}
cd {{nome}}
{{setup commands}}
```
Leia: `docs/FONTE_DA_VERDADE.md`, `ATIVIDADES.md`, `CONTEXT.md`.
```

---

## 4. Persistência de memória — as 4 camadas

Um projeto longo tem **diferentes tipos de informação** que precisam ser persistidas em lugares diferentes. Misturar camadas gera atrito.

| Camada | Arquivo | O que vai aqui | Frequência de mudança |
|---|---|---|---|
| **Decisão de produto** | `FONTE_DA_VERDADE.md` | Regras de negócio, escopo, atores | Raríssima |
| **Decisão técnica** | `ARQUITETURA.md`, `BANCO_DE_DADOS.md` | Estrutura, schema, padrões | Esporádica |
| **Backlog** | `ATIVIDADES.md` | O que falta fazer | Sempre que tarefa entra/sai |
| **Memória de execução** | `CONTEXT.md` | Armadilhas, fix de bugs sutis, convenções | Sempre que aprende algo novo |

**Adicionalmente:**
- `CLAUDE.md` na raiz é o "índice rápido" — links e atalhos para quem chega zero contexto.
- Memória do Claude Code (`~/.claude/projects/.../memory/`) guarda preferências do usuário entre sessões — não é onde decisões de projeto vivem.

**Regra:** se você não sabe onde uma informação vai, ela provavelmente é decisão de produto e vai na `FONTE_DA_VERDADE`.

---

## 5. Workflow com Claude Code

### 5.1 Primeiro prompt do dia (abertura de sessão)

```
Estou trabalhando no projeto {{NOME}}. Documentos canônicos em ./docs/:
- FONTE_DA_VERDADE.md (master)
- ARQUITETURA.md
- BANCO_DE_DADOS.md
- ROADMAP_TECNICO.md (sigo as tarefas em ordem)

Backlog: ATIVIDADES.md
Memória técnica: CONTEXT.md

Próxima tarefa: {{X.Y}} do ROADMAP. Antes de codar:
1. Leia a tarefa {{X.Y}}
2. Leia as seções referenciadas pelo prompt da tarefa
3. Confirme que entendeu o entregável
4. Só então implemente

Se houver ambiguidade ou faltar informação, **pare e pergunte**. Não invente.
```

### 5.2 Estrutura de um prompt de tarefa

**Errado** (vago):
```
Implemente o checkout do carrinho com pagamento.
```

**Certo** (atômico, com âncoras):
```
Tarefa: ROADMAP_TECNICO.md §3.4 (CheckoutService).
Regras: FONTE_DA_VERDADE.md §4.3 (Carrinho) e §4.4 (Booking).
Schema: BANCO_DE_DADOS.md §2.5 (booking_groups) e §2.6 (bookings).
Restrições:
- Não criar UI ainda (vem em 3.5)
- Não chamar serviço externo real — mock no spec
- Cobrir spec: happy path + carrinho vazio + slot já reservado
Entregável: app/services/checkout_service.rb + spec, sem mais nada.
```

### 5.3 Padrão "Plan → Act → Verify → Commit"

Para qualquer tarefa que toca >1 arquivo, use este loop:

1. **Plan** — peça para Claude listar arquivos que vai criar/modificar e por quê. Aprove ou ajuste antes de codar.
2. **Act** — Claude implementa.
3. **Verify** — peça `git diff` + `git status` + rodar testes/lint. Você lê o diff antes de aceitar.
4. **Commit** — commit atômico com mensagem descritiva (`feat:`, `fix:`, `docs:`, `refactor:`).

### 5.4 Como evitar invenção

Três técnicas que funcionam:

1. **Ancorar antes de pedir.** Sempre cite seção do doc. Se a info não está no doc, atualize o doc primeiro.
2. **Restringir o escopo explicitamente.** "Não crie X. Não toque em Y."
3. **Pedir confirmação antes de codar tarefas grandes.** "Antes de escrever código, me liste em bullets o que você vai criar e por quê."

### 5.5 Quando algo muda

Mudou regra de negócio? **Fluxo correto:**

1. **Pare de codar.**
2. Atualize `FONTE_DA_VERDADE.md` (e docs derivados se preciso).
3. Adicione entrada na tabela "Decisões técnicas registradas" — com data e justificativa.
4. Só então prompte o Claude com a tarefa de aplicar a mudança no código.

Pular o passo 2 cria a contradição "código não bate com doc" — origem de quase todo bug futuro.

---

## 6. Ferramentas do Claude Code que mudam o jogo

### 6.1 Subagentes — quando usar

| Subagente | Quando usar | Quando NÃO usar |
|---|---|---|
| **Explore** | Mapear código desconhecido em >3 arquivos | Buscar 1 string específica (use `grep`) |
| **Plan** | Tarefa grande que precisa de design antes do código | Tarefa atômica do ROADMAP |
| **general-purpose** | Pesquisa multi-passo aberta | Tarefa com escopo claro |

**Regra:** subagente é caro (sessão isolada, sem seu contexto). Use **só** quando o ganho de paralelismo ou contexto isolado compensa.

### 6.2 Plan Mode (`/plan` ou ExitPlanMode)

Use **antes** de tarefas com efeito colateral grande (mexer em DB, deploy, refactor). Em plan mode, Claude só lê — não escreve. Você revisa o plano e libera.

### 6.3 Modelos: Opus vs Sonnet vs Haiku

| Modelo | Quando usar | Custo relativo |
|---|---|---|
| **Opus 4.7** | Design de sistemas, escrita de docs canônicos, decisões arquiteturais, prompts longos | Alto |
| **Sonnet 4.6** | Implementação de tarefa do ROADMAP, debugging, code review | Médio |
| **Haiku 4.5** | Tarefas mecânicas (renomear, mover arquivos, formatar) | Baixo |

Troque com `/model`. Para tarefas críticas (ex: definir o `ROADMAP_TECNICO`), vale pagar Opus.

### 6.4 Slash commands úteis

- `/plan` — entra em modo de planejamento
- `/fast` — Opus em modo rápido
- `/loop <intervalo> <tarefa>` — executa tarefa repetidamente
- `/clear` — limpa contexto (use entre tarefas muito diferentes)

### 6.5 CLAUDE.md como instruções permanentes

Tudo que você se cansa de repetir — comandos, convenções, "nunca faça X" — vai no `CLAUDE.md` da raiz. É lido automaticamente em cada sessão.

---

## 7. Rituais de sessão

### 7.1 Abertura

1. `git status` — entender o estado.
2. `git log --oneline -5` — relembrar últimos commits.
3. Ler `ATIVIDADES.md` — o que está pendente.
4. Escolher 1 tarefa.
5. Prompt de abertura (§5.1) com a tarefa específica.

### 7.2 Durante

- Cada commit deve ser **atômico** — uma tarefa, uma intenção.
- Mensagens de commit: `tipo: o que mudou` (sem o "porquê" — esse já está no PR ou no doc).
- Se Claude propõe scope creep ("aproveitando que estou aqui, vou refatorar X"), **freie**.

### 7.3 Encerramento

1. Atualizar `ATIVIDADES.md` (marcar concluído ou anotar o que ficou).
2. Atualizar `CONTEXT.md` se aprendeu algo não-óbvio (armadilha, decisão sutil).
3. Push final: `git push`.
4. Um commit final tipo `chore: atualiza backlog` se mudou só docs.

> **Sintoma de ritual quebrado:** acordar amanhã sem saber onde parou. A culpa é da etapa 1 ou 2 não ter sido feita.

---

## 8. Lições aprendidas (com exemplos reais do VDC)

Cada item é um erro real que **seria cometido** sem o doc correspondente.

| Sem qual doc | O que aconteceria | Como o doc previne |
|---|---|---|
| `FONTE_DA_VERDADE` | Regras de cancelamento de booking inconsistentes entre Service e Controller | §4.4 fixa estados e transições; toda implementação cita essa seção |
| `BANCO_DE_DADOS` | UUID vs bigint inconsistente; PaperTrail (que assume bigint) quebraria em produção armazenando `item_id = 0` | §1 fixa UUID como PK global; migration de PaperTrail tem ajuste documentado |
| `ROADMAP_TECNICO` | CheckoutService implementado antes do model Booking ter `status` — refator obrigatório dias depois | Tarefa do Service tem "Depende de: 1.4 (model Booking com status)" |
| `FAQ` da FONTE | Claude proporia React para "telas dinâmicas" e Stripe em vez de MercadoPago | FAQ tem entradas explícitas: "Por que não React?" e "Por que MercadoPago e não Stripe?" |
| `ARQUITETURA` | Lógica de pagamento no controller, espalhada por 3 actions | §3 declara "lógica de pagamento sempre em Service" |
| `MODULOS` | Edge case "carrinho com slot expirado entre clique e checkout" só descoberto em produção | Módulo Carrinho lista esse edge case no design |
| `DESIGN_SYSTEM` | Cada view com classes Tailwind ad-hoc; refator para componentes meses depois | Tokens e componentes definidos antes da primeira view |
| `CLAUDE.md` | Cada sessão começa explicando comandos básicos (`bin/rspec`, `bin/dev`) | Lido automaticamente; Claude já sabe |
| `CONTEXT.md` | Bug do `FOR UPDATE` + `COUNT(*)` voltaria em outra service no futuro | Documentado a solução: `.load` antes de `.size` |
| `ATIVIDADES.md` | Pendências esquecidas; "tinha algo a fazer aqui mas não lembro" | Backlog priorizado, sempre disponível |

**Padrão observado:** os docs não previnem erros de código — previnem **erros de decisão**. Claude implementa bem o que é especificado; o que não é especificado, ele adivinha — e é aí que o bug nasce.

### 8.1 Lições específicas técnicas (vão para `CONTEXT.md` do projeto)

- **PaperTrail + UUID:** se o projeto usa UUID como PK, a migration padrão do PaperTrail (`item_id` como `bigint`) precisa virar `string`. Sem isso, todos os registros gravam `item_id = 0` e queries de associação retornam vazio.
- **`FOR UPDATE` + agregações:** `Model.lock("FOR UPDATE").size` gera `COUNT(*) FOR UPDATE`, que o Postgres rejeita. Solução: `.load` antes de `.size`.
- **PaperTrail no RSpec:** o framework oficial (`require "paper_trail/frameworks/rspec"`) desabilita versionamento por padrão. Habilite em testes específicos com `versioning: true`.
- **Mocks por boundary:** mocks só em sistemas externos (HTTP, mail). Mockar AR ou Service interno cria divergência mock/prod e mascara bugs.
- **Webhook secret em dev:** prefix `mock-` no secret bypassa validação HMAC sem código condicional espalhado.

---

## 9. Checklist de prontidão

Antes de pedir ao Claude Code a primeira linha de código, você deve responder **todas** as perguntas abaixo apenas consultando os docs:

### Produto
- [ ] Em uma frase, o que esse sistema faz?
- [ ] Quais são os 3 fluxos mais críticos do usuário?
- [ ] O que esse sistema **não** faz (escopo negativo)?
- [ ] Qual a métrica de sucesso?

### Atores
- [ ] Quantos roles existem? Como cada um entra na plataforma?
- [ ] Quem pode fazer o quê? (Cada ação crítica tem dono claro?)

### Stack
- [ ] Toda escolha de tecnologia tem justificativa por escrito?
- [ ] Existe lista explícita do que **não usar**?

### Dados
- [ ] Todas as entidades têm schema fechado (campos, tipos, null, default)?
- [ ] Todos os índices têm justificativa (qual query atende)?
- [ ] Todas as constraints (check, unique, FK) estão registradas?
- [ ] PK é UUID ou bigint? (Decisão única, global.)

### Regras de negócio
- [ ] Cada entidade com estado tem máquina de estados documentada?
- [ ] Cada validação está no doc **e** será replicada em código + banco?
- [ ] Edge cases conhecidos (concorrência, expiração, cancelamento) têm comportamento definido?

### Roadmap
- [ ] Cada tarefa do ROADMAP tem prompt pronto?
- [ ] Cada tarefa declara dependências?
- [ ] A ordem respeita: schema → model → service → controller → view?

### FAQ
- [ ] As 5 perguntas mais óbvias que um dev faria estão respondidas no FAQ?

### Operacional
- [ ] `CLAUDE.md` na raiz tem comandos básicos?
- [ ] `.gitignore` cobre `.env` e diretórios sensíveis?
- [ ] CI já está minimamente configurado?

Se algum item está marcado, **pare** e complete antes de codar. O custo de uma hora preenchendo doc é menor que o de um dia refatorando código.

---

## 10. Prompt engineering específico para Claude Code

### 10.1 Ele lê arquivos — use isso

- **Não cole** o conteúdo do doc no prompt. Cite o caminho.
- Errado: "Considere as seguintes regras: [200 linhas coladas]"
- Certo: "Aplique as regras de FONTE_DA_VERDADE.md §4.3"
- Vantagem: contexto fica menor, Claude lê só o que precisa, e você sempre referencia a versão atual.

### 10.2 Ele executa comandos — peça verificação ativa

Em vez de "implemente X e me mostre", peça:

```
Implemente a tarefa 1.4. Em seguida:
1. Rode `bin/rails db:migrate`
2. Rode `bundle exec rspec spec/models/booking_spec.rb`
3. Me mostre a saída de ambos
4. Se algum falhar, conserte antes de me devolver
```

### 10.3 Ele tem contexto de projeto — aproveite

`CLAUDE.md` na raiz é lido automaticamente. Use para:
- Comandos comuns
- Convenções do projeto
- Caminho dos docs canônicos
- O que **nunca** fazer

### 10.4 Padrões de prompt que funcionam

| Padrão | Quando usar | Exemplo |
|---|---|---|
| **Plan-then-act** | Tarefas com >1 arquivo | "Antes de codar, liste em bullets os arquivos que vai criar/modificar e por quê. Espere meu OK." |
| **Restrict scope** | Tarefa atômica | "Crie APENAS o service e o spec. Não toque em controller, view, rota." |
| **Quote source** | Ambiguidade detectada | "Cite literalmente o trecho da FONTE_DA_VERDADE que justifica essa decisão." |
| **Verify after** | Mudança em código existente | "Após editar, rode `git diff` e confirme que só os arquivos pretendidos mudaram." |
| **Stop and ask** | Lacuna de informação | "Se faltar info nos docs, **pare e pergunte**. Não invente default." |
| **Show diff before commit** | Antes de qualquer commit | "Mostre `git diff --stat` e me deixe aprovar antes do commit." |

### 10.5 Anti-padrões — o que evitar

- **Prompt aberto**: "melhore o código" → vira refatoração de 30 arquivos.
- **Múltiplas tarefas em um prompt**: "implemente 1.4, 1.5 e 1.6" → contexto explode, qualidade cai.
- **Pedir sem âncora de doc**: "como você acha que devemos fazer X?" → opinião em vez de execução.
- **Aceitar "implementei tudo" sem diff**: sempre peça `git status` + `git diff` antes de aprovar.
- **Atualizar código sem atualizar doc**: gera dívida de documentação que silencia o método inteiro.
- **Usar Opus para tarefa mecânica**: desperdício; Sonnet ou Haiku resolve mais barato.
- **Não usar `/clear` entre tarefas distintas**: contexto cresce, qualidade degrada.

---

## 11. Troubleshooting comum

### 11.1 "Claude continua sugerindo X mesmo eu dizendo para não usar"
**Causa:** instrução está no chat (efêmera) e não nos docs.
**Fix:** mova a proibição para `CLAUDE.md` ou para a seção "Não usar" da `FONTE_DA_VERDADE`.

### 11.2 "Implementação não bate com o que pedi"
**Causa:** prompt sem âncora de doc OU doc desatualizado.
**Fix:** Veja qual dos dois. Se o doc está correto, prompte de novo citando seção.

### 11.3 "Sessão nova começou perdida"
**Causa:** `CLAUDE.md` não existe ou não tem links para os docs.
**Fix:** crie `CLAUDE.md` na raiz com links + comandos básicos.

### 11.4 "Bug que apareceu em produção mas não nos testes"
**Causa típica:** mock cobrindo lógica que era bug real (ex: AR mockado pulando constraint).
**Fix:** registre em `CONTEXT.md` com sintoma + causa + solução. Adicione regra "mocks só em boundary" na ARQUITETURA se ainda não tem.

### 11.5 "Não sei mais onde parei"
**Causa:** ritual de encerramento não foi feito.
**Fix:** sempre `ATIVIDADES.md` atualizado + `CONTEXT.md` com aprendizados.

### 11.6 "Refator gigante quebrou tudo"
**Causa:** mudança feita sem atualizar a `FONTE_DA_VERDADE` primeiro.
**Fix:** nunca pular o §5.5. Doc primeiro, código depois.

---

## Apêndice — fluxo resumido (1 página)

```
0. Validou o produto? (Pergunta certa, métrica clara)
       ↓ sim
1. Escreva FONTE_DA_VERDADE.md (master)
       ↓
2. Escreva ARQUITETURA.md + BANCO_DE_DADOS.md (derivados)
       ↓
3. Escreva MODULOS.md + DESIGN_SYSTEM.md (se aplicável)
       ↓
4. Escreva ROADMAP_TECNICO.md (com prompt pronto por tarefa)
       ↓
5. Crie CLAUDE.md na raiz (atalhos para o Claude Code)
       ↓
6. Rode o checklist de prontidão — não codar enquanto faltar item
       ↓
7. Para cada tarefa do ROADMAP:
       a. Prompt atômico citando doc
       b. Plan-then-act se >1 arquivo
       c. Verify after (testes + diff)
       d. Commit atômico
       e. Marca tarefa como feita em ATIVIDADES.md
       f. Se aprendeu algo novo, anota em CONTEXT.md
       ↓
8. Quando regra mudar: doc primeiro, código depois — SEMPRE
       ↓
9. Encerra sessão: ATIVIDADES + CONTEXT atualizados, push final
```

> **Resumo em uma frase:** os docs não são burocracia — são o **prompt persistente** que mantém o Claude Code coerente entre sessões e tarefas, e transforma o dev solo em orquestrador em vez de codificador.
