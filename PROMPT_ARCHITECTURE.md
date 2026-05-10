# PROMPT_ARCHITECTURE.md

> **Guia de arquitetura de documentação para projetos com Claude Code.**
> Template reutilizável e independente de stack, derivado da abordagem que produziu o projeto Videira Dental Clinic (VDC).
> Tempo de leitura: ~15 min. Tempo de aplicação em um projeto novo: ~4-8h de redação de docs antes da primeira linha de código.

---

## Sumário

1. [Por que esse método funciona](#1-por-que-esse-método-funciona)
2. [Os 6 documentos da fonte da verdade](#2-os-6-documentos-da-fonte-da-verdade)
3. [Templates preenchíveis](#3-templates-preenchíveis)
4. [Workflow com o Claude Code](#4-workflow-com-o-claude-code)
5. [Lições aprendidas (com exemplos do VDC)](#5-lições-aprendidas-com-exemplos-do-vdc)
6. [Checklist de prontidão](#6-checklist-de-prontidão)
7. [Prompt engineering específico para Claude Code](#7-prompt-engineering-específico-para-claude-code)

---

## 1. Por que esse método funciona

O Claude Code não é um chat genérico. Ele lê e escreve arquivos, executa comandos, navega o repositório e mantém contexto entre tarefas. Isso muda a forma de trabalhar com ele:

| Sem documentação prévia | Com documentação prévia |
|---|---|
| Cada prompt re-explica o projeto. | Cada prompt referencia uma seção curta de um doc canônico. |
| Claude inventa regras quando há lacuna. | Claude consulta o doc; se a resposta não existe, **pergunta**. |
| Decisões mudam entre sessões. | Decisões são fixadas e versionadas em arquivos. |
| Tarefas são implementadas fora de ordem. | O ROADMAP impõe a sequência correta. |
| Refatorações constantes para alinhar contradições. | Contradições são pegas no texto, não no código. |

Três princípios sustentam o método:

- **Fonte da verdade única**: contradição entre dois documentos é bug; o documento master vence.
- **Prompts atômicos**: uma tarefa do ROADMAP por prompt, com referência explícita à seção do doc relevante.
- **Decisão antes de código**: cada "vai usar X ou Y?" é resolvido por escrito antes de gerar arquivos.

---

## 2. Os 6 documentos da fonte da verdade

A ordem de criação importa: cada doc usa decisões dos anteriores.

| # | Documento | Função | Tamanho típico |
|---|---|---|---|
| 1 | `FONTE_DA_VERDADE.md` | Master. Define o produto, stack, regras de negócio, atores, FAQ. | 800-2000 linhas |
| 2 | `ARQUITETURA.md` | Camadas, pastas, responsabilidades, comunicação entre camadas. | 400-1000 linhas |
| 3 | `BANCO_DE_DADOS.md` | Schema completo, migrations, índices, constraints, ERD. | 300-800 linhas |
| 4 | `MODULOS.md` | Mapa funcional dividido em módulos (carrinho, pagamento, auth...). | 200-600 linhas |
| 5 | `ROADMAP_TECNICO.md` | Tarefas em ordem de dependência, **com prompt pronto para IA**. | 500-1500 linhas |
| 6 | `DESIGN_SYSTEM.md` | Tokens visuais e componentes de UI. Pode ser pulado em projetos só de backend. | 200-600 linhas |

> **Regra:** se o doc N contradiz o doc N-1, o doc N está errado. Conserte o N, não o N-1. O master (FONTE_DA_VERDADE) é a autoridade final.

### Seções obrigatórias vs opcionais

**Obrigatórias em qualquer projeto:**

- FONTE_DA_VERDADE: definição do produto, stack congelada, atores/roles, regras de negócio, fluxos principais, FAQ, decisões registradas.
- ARQUITETURA: estrutura de pastas, camadas e suas responsabilidades.
- BANCO_DE_DADOS: schema por tabela, índices, constraints, ERD textual.
- ROADMAP_TECNICO: tarefas ordenadas com prompt pronto.

**Opcionais (incluir se aplicável):**

- MODULOS: pule se o projeto cabe em <5 entidades.
- DESIGN_SYSTEM: pule em projetos sem UI ou que apenas consomem componentes prontos.
- Glossário: útil em domínios com jargão (saúde, jurídico, finanças).

---

## 3. Templates preenchíveis

Copie cada bloco abaixo para um arquivo `.md` separado e preencha os `{{PLACEHOLDERS}}`. Os `<!-- comentários -->` explicam o que cada seção espera.

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

> **Não usar:** {{tecnologias proibidas e por quê — evita Claude propor alternativas}}

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

### 4.2 {{Entidade B}}

- {{...}}

---

## 5. ERD canônico

<!-- ASCII ou Mermaid — não precisa ser bonito, precisa ser inequívoco -->

```
{{Entidade A}} 1 ─── N {{Entidade B}}
{{Entidade B}} N ─── 1 {{Entidade C}}
```

---

## 6. Fluxos completos

### 6.1 {{Fluxo principal — ex: Checkout}}

**Happy path:**
1. {{Ator}} faz {{ação}}.
2. Sistema {{resposta}}.
3. ...

**Sad paths:**
- Se {{condição}}: {{comportamento}}.
- Se {{outra condição}}: {{outro comportamento}}.

### 6.2 {{Outro fluxo}}

{{...}}

---

## 7. Mapa de telas e rotas

| Rota | Quem acessa | O que mostra |
|---|---|---|
| `GET /` | público | {{...}} |
| `GET /{{x}}` | {{role}} | {{...}} |

---

## 8. Convenções de código

- Nomes em {{idioma}} (modelos: {{X}}, variáveis: {{Y}}).
- Comentários: {{quando sim, quando não}}.
- Commits: {{padrão — ex: conventional commits}}.

---

## 9. Variáveis de ambiente

| Var | Onde usar | Exemplo |
|---|---|---|
| `{{VAR_1}}` | {{...}} | {{...}} |

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

**P: {{...}}**
R: {{...}}

---

## 12. Como usar este documento com IA

- **Certo:** "Implemente a tarefa 3.2 do ROADMAP_TECNICO. Regra de negócio: ver FONTE_DA_VERDADE seção 4.3."
- **Errado:** "Implemente checkout." (sem referência → Claude inventa)
- Se a resposta não está no doc: **pare, atualize o doc, depois prompt**.
```

### 3.2 Template — `ARQUITETURA.md`

```markdown
# {{NOME_DO_PROJETO}} — ARQUITETURA.md

## 1. Princípios

- {{princípio 1 — ex: "fat models, skinny controllers"}}
- {{princípio 2 — ex: "lógica de negócio em Services, nunca em Controllers"}}
- {{princípio 3}}

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

## 4. Comunicação entre camadas

```
Controller → Service → Model → DB
                    ↘ Job (async)
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

- {{como evitar race conditions em X}}
- {{lock otimista? pessimista? advisory locks?}}

## 8. I18n / localização

- Idioma default: `{{pt-BR}}`
- Estratégia: {{arquivos YAML por idioma / único arquivo / etc}}

## 9. Estrutura de testes

- Framework: {{X}}
- O que **deve** ter teste: {{services, fluxos críticos, policies}}
- O que **não precisa**: {{getters triviais, views estáticas}}

## 10. Lint / formatação

- Ferramenta: {{X}}
- Configuração: ver `.{{tool}}rc`
```

### 3.3 Template — `BANCO_DE_DADOS.md`

```markdown
# {{NOME_DO_PROJETO}} — BANCO_DE_DADOS.md

## 1. Convenções globais

- Primary key: `{{uuid|bigint}}` (justificativa: {{...}})
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
| 003 | `CreateX` | x | 002 |

## 4. ERD detalhado

```
{{ASCII ou Mermaid completo}}
```

## 5. Seeds

- Dados mínimos para `{{ambiente}}`: {{lista}}
- Localização: `{{caminho/seeds}}`
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

### 0.2 {{...}} — B
{{...}}

---

## FASE 1 — Modelos e auth (~Xh)

### 1.1 {{Migration X}} — B
**Depende de:** 0.4
**Por que agora:** Service que vem em 1.5 precisa do modelo
**Prompt para IA:**
```
Implemente a tarefa 1.1 do ROADMAP. Schema da tabela: ver BANCO_DE_DADOS.md seção 2.3.
Regras de validação: ver FONTE_DA_VERDADE seção 4.2.
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

### 2.2 Card
{{...}}

## 3. Tradução Figma → código

| Frame Figma | Componente código | Observações |
|---|---|---|
| `Card / Slot` | `app/views/shared/_slot_card.{{ext}}` | usa token `surface` |
```

---

## 4. Workflow com o Claude Code

### 4.1 Iniciando uma sessão (primeiro prompt do dia)

```
Estou trabalhando no projeto {{NOME}}. Os documentos canônicos estão em ./docs/:
- FONTE_DA_VERDADE.md (master — toda regra de negócio está aqui)
- ARQUITETURA.md
- BANCO_DE_DADOS.md
- ROADMAP_TECNICO.md (sigo as tarefas em ordem)

Próxima tarefa: {{X.Y}} do ROADMAP. Antes de codar:
1. Leia a tarefa {{X.Y}} no ROADMAP_TECNICO.md
2. Leia as seções referenciadas pelo prompt da tarefa
3. Confirme que entendeu o entregável
4. Só então implemente

Se houver ambiguidade entre os docs ou faltar informação, **pare e pergunte**. Não invente.
```

### 4.2 Estrutura de um prompt de tarefa

**Errado** (vago, sem âncora):
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
- Não chamar MercadoPago real — mock no spec
- Cobrir spec: happy path + carrinho vazio + slot já reservado
Entregável: app/services/checkout_service.rb + spec, sem mais nada.
```

### 4.3 Como evitar invenção

Três técnicas que funcionam:

1. **Ancorar antes de pedir.** Sempre cite seção do doc. Se a info não está no doc, atualize o doc primeiro.
2. **Restringir o escopo explicitamente.** "Não crie X. Não toque em Y." Claude tende a expandir; restrinja.
3. **Pedir confirmação antes de codar tarefas grandes.** "Antes de escrever código, me liste em bullets o que você vai criar e por quê." Você vê desvios antes do diff.

### 4.4 Avançando fase por fase

- Termine cada tarefa do ROADMAP **completamente** (código + teste + commit) antes da próxima.
- Marque a tarefa como concluída no próprio ROADMAP (`[x]` ou tachado).
- Ao final de cada fase, abra um commit "fase N concluída" e revise.

### 4.5 Quando algo muda

Mudou regra de negócio no meio do projeto? Fluxo correto:

1. **Pare de codar.**
2. Atualize `FONTE_DA_VERDADE.md` (e docs derivados se preciso).
3. Atualize a entrada na tabela de "Decisões técnicas registradas" — com data e justificativa.
4. Só então prompte o Claude com a tarefa de aplicar a mudança no código.

Pular o passo 2 cria a contradição "código não bate com doc" — origem de quase todo bug futuro.

---

## 5. Lições aprendidas (com exemplos do VDC)

Cada item abaixo é um erro real que **seria cometido** sem o doc correspondente.

| Sem qual doc | O que aconteceria | Como o doc previne |
|---|---|---|
| `FONTE_DA_VERDADE` | Claude inventaria regras de cancelamento de booking inconsistentes entre Service e Controller. | §4.4 fixa estados e transições; toda implementação cita essa seção. |
| `BANCO_DE_DADOS` | UUID vs bigint inconsistente; PaperTrail (que assume bigint por padrão) quebraria em produção. | §1 fixa UUID como PK global; migration de PaperTrail tem ajuste documentado. |
| `ROADMAP_TECNICO` | CheckoutService implementado antes do model Booking ter `status` — refatoração obrigatória 2 dias depois. | Tarefa do Service tem "Depende de: 1.4 (model Booking com status)". |
| `FAQ` da FONTE_DA_VERDADE | Claude proporia React para "telas dinâmicas de calendário" e Stripe em vez de MercadoPago (mais conhecido globalmente). | FAQ tem entradas explícitas: "Por que não React?" e "Por que MercadoPago e não Stripe?". |
| `ARQUITETURA` | Lógica de pagamento iria parar no controller (mais fácil), espalhada por 3 actions. | §3 declara "lógica de pagamento sempre em Service; controller só orquestra". |
| `MODULOS` | Edge case "carrinho com slot expirado entre clique e checkout" só seria descoberto em produção. | Módulo Carrinho lista esse edge case no momento do design. |
| `DESIGN_SYSTEM` | Cada view usaria classes Tailwind ad-hoc; refatoração para componentes meses depois. | Tokens e componentes definidos antes da primeira view. |

**Padrão observado:** os docs não previnem erros de código — previnem **erros de decisão**. Claude implementa bem o que é especificado; o que não é especificado, ele adivinha — e é aí que o bug nasce.

---

## 6. Checklist de prontidão

Antes de pedir ao Claude Code a primeira linha de código, você deve conseguir responder **todas** as perguntas abaixo apenas consultando os docs:

### Produto
- [ ] Em uma frase, o que esse sistema faz?
- [ ] Quais são os 3 fluxos mais críticos do usuário?
- [ ] O que esse sistema **não** faz (escopo negativo)?

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
- [ ] Cada entidade com estado tem máquina de estados documentada (transições e gatilhos)?
- [ ] Cada validação está no doc **e** será replicada em código + banco?
- [ ] Edge cases conhecidos (concorrência, expiração, cancelamento) têm comportamento definido?

### Roadmap
- [ ] Cada tarefa do ROADMAP tem prompt pronto?
- [ ] Cada tarefa declara dependências?
- [ ] A ordem respeita: schema → model → service → controller → view?

### FAQ
- [ ] As 5 perguntas mais óbvias que um dev faria estão respondidas no FAQ?

Se algum item está marcado, **pare** e complete antes de codar. O custo de uma hora preenchendo doc é menor que o de um dia refatorando código.

---

## 7. Prompt engineering específico para Claude Code

O Claude Code se diferencia de um chat genérico em três pontos que mudam como você prompta:

### 7.1 Ele lê arquivos — use isso

- **Não cole** o conteúdo do doc no prompt. Cite o caminho.
- Errado: "Considere as seguintes regras: [200 linhas coladas]"
- Certo: "Aplique as regras de FONTE_DA_VERDADE.md §4.3"
- Vantagem: contexto fica menor, Claude lê só o que precisa, e você sempre referencia a versão atual do doc.

### 7.2 Ele executa comandos — peça verificação ativa

Em vez de "implemente X e me mostre", peça "implemente X, rode os testes, me mostre o resultado". Você terceiriza a verificação.

```
Implemente a tarefa 1.4. Em seguida:
1. Rode `bin/rails db:migrate`
2. Rode `bundle exec rspec spec/models/booking_spec.rb`
3. Me mostre a saída de ambos
4. Se algum falhar, conserte antes de me devolver
```

### 7.3 Ele tem contexto de projeto — aproveite

Crie um `CLAUDE.md` na raiz do repo com:
- Comandos comuns (build, test, lint, run)
- Convenções do projeto (nomenclatura, idioma de commits)
- Caminho dos docs canônicos
- O que **nunca** fazer (ex: "nunca rode `db:reset` em produção")

Esse arquivo é lido automaticamente pelo Claude Code em cada sessão. É a forma mais barata de evitar repetir instruções básicas.

### 7.4 Padrões de prompt que funcionam

| Padrão | Quando usar | Exemplo |
|---|---|---|
| **Plan-then-act** | Tarefas com >1 arquivo | "Antes de codar, liste em bullets os arquivos que vai criar/modificar e por quê. Espere meu OK." |
| **Restrict scope** | Tarefa atômica do ROADMAP | "Crie APENAS o service e o spec. Não toque em controller, view, rota." |
| **Quote source** | Ambiguidade detectada | "Cite literalmente o trecho da FONTE_DA_VERDADE que justifica essa decisão." |
| **Verify after** | Mudança em código existente | "Após editar, rode `git diff` e confirme que só os arquivos pretendidos mudaram." |
| **Stop and ask** | Lacuna de informação | "Se faltar info nos docs, **pare e pergunte**. Não invente default." |

### 7.5 Anti-padrões — o que evitar

- **Prompt aberto**: "melhore o código" → vira refatoração de 30 arquivos.
- **Múltiplas tarefas em um prompt**: "implemente 1.4, 1.5 e 1.6" → contexto explode, qualidade cai.
- **Pedir sem âncora de doc**: "como você acha que devemos fazer X?" → opinião em vez de execução.
- **Aceitar "implementei tudo" sem diff**: sempre peça `git status` + `git diff` antes de aprovar.
- **Atualizar código sem atualizar doc**: gera dívida de documentação que silencia o método inteiro.

---

## Apêndice — fluxo resumido (1 página)

```
1. Escreva FONTE_DA_VERDADE.md (master)
       ↓
2. Escreva ARQUITETURA.md + BANCO_DE_DADOS.md (derivados)
       ↓
3. Escreva MODULOS.md + DESIGN_SYSTEM.md (se aplicável)
       ↓
4. Escreva ROADMAP_TECNICO.md (com prompt pronto por tarefa)
       ↓
5. Rode o checklist de prontidão — não codar enquanto faltar item
       ↓
6. Crie CLAUDE.md na raiz (atalhos para o Claude Code)
       ↓
7. Para cada tarefa do ROADMAP:
       a. Prompt atômico citando doc
       b. Plan-then-act se >1 arquivo
       c. Verify after (testes + diff)
       d. Commit
       e. Marca tarefa como feita
       ↓
8. Quando regra mudar: doc primeiro, código depois — SEMPRE
```

> **Resumo em uma frase:** os docs não são burocracia — são o **prompt persistente** que mantém o Claude Code coerente entre sessões e tarefas.
