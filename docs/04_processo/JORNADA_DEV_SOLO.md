# JORNADA_DEV_SOLO.md — Construindo software com Claude Code

> Guia prático para devs solo que querem usar o Claude Code com maestria.
> Cada parte tem **conceito + desafio**. Faça os desafios na ordem; cada um constrói sobre o anterior.
> Tempo total estimado: **40-60h** distribuídas ao longo de 2-4 semanas.

---

## Sumário

- [Parte 1 — Conceitos fundamentais](#parte-1--conceitos-fundamentais)
- [Parte 2 — Fundamentos (4 desafios)](#parte-2--fundamentos)
  - [Desafio 1 — Sua primeira FONTE_DA_VERDADE](#desafio-1--sua-primeira-fonte_da_verdade)
  - [Desafio 2 — Estruturando o ROADMAP_TECNICO](#desafio-2--estruturando-o-roadmap_tecnico)
  - [Desafio 3 — O CLAUDE.md correto](#desafio-3--o-claudemd-correto)
  - [Desafio 4 — Setup colaborativo com Claude](#desafio-4--setup-colaborativo-com-claude)
- [Parte 3 — Implementação (5 desafios)](#parte-3--implementação)
  - [Desafio 5 — Banco de dados sem voltar atrás](#desafio-5--banco-de-dados-sem-voltar-atrás)
  - [Desafio 6 — Service com regra de negócio](#desafio-6--service-com-regra-de-negócio)
  - [Desafio 7 — Integração externa robusta](#desafio-7--integração-externa-robusta)
  - [Desafio 8 — Suite de testes que importa](#desafio-8--suite-de-testes-que-importa)
  - [Desafio 9 — CRUD bem feito](#desafio-9--crud-bem-feito)
- [Parte 4 — Operação (3 desafios)](#parte-4--operação)
  - [Desafio 10 — CI que pega bugs](#desafio-10--ci-que-pega-bugs)
  - [Desafio 11 — Deploy + smoke test](#desafio-11--deploy--smoke-test)
  - [Desafio 12 — Manutenção e evolução](#desafio-12--manutenção-e-evolução)
- [Parte 5 — Maestria](#parte-5--maestria)
- [Apêndice — Mapa de skills](#apêndice--mapa-de-skills)

---

## Parte 1 — Conceitos fundamentais

### 1.1 O que muda quando você programa com Claude Code

Você deixa de **escrever código** e passa a **dirigir um colega que escreve**. As habilidades que valorizam:

| Antes (dev sozinho) | Agora (dev com Claude Code) |
|---|---|
| Velocidade de digitação | Velocidade de **decisão** |
| Memória de sintaxe | Clareza de **especificação** |
| Resolver bugs sozinho | Saber qual **contexto** dar ao Claude |
| Documentação como dever | Documentação como **prompt persistente** |
| Refatorar quando dá tempo | Decidir **antes** de codar |

**Mindset shift:** o trabalho é orquestrar, não digitar.

### 1.2 Os 5 princípios que vão guiar todos os desafios

1. **Decisão antes de código** — toda escolha técnica é resolvida em texto antes de virar arquivo.
2. **Fonte da verdade única** — um documento master; derivados consistentes; contradição = bug.
3. **Prompt atômico** — uma tarefa, um prompt, com âncora explícita ao doc.
4. **Verify before trust** — `git diff` + testes antes de cada commit.
5. **Aprenda → registre** — armadilha resolvida hoje vai para `CONTEXT.md` e nunca mais te morde.

### 1.3 As 4 camadas de persistência que você vai usar

| Camada | Onde mora | Para quê |
|---|---|---|
| Decisão de produto | `docs/FONTE_DA_VERDADE.md` | Regras de negócio, escopo |
| Decisão técnica | `docs/ARQUITETURA.md` + `docs/BANCO_DE_DADOS.md` | Estrutura, schema |
| Backlog vivo | `ATIVIDADES.md` | O que falta fazer |
| Memória de execução | `CONTEXT.md` | Armadilhas e soluções não-óbvias |

E o `CLAUDE.md` na raiz — o "atalho" lido em toda sessão.

### 1.4 Como ler este documento

Cada desafio tem:

- **Cenário** — o contexto fictício (ou real, se quiser usar para um projeto seu)
- **O que você vai aprender** — skills concretas
- **Tarefa** — o que entregar
- **Critérios de sucesso** — como saber que está pronto
- **Armadilhas comuns** — onde a maioria dos devs erra
- **Quando pedir ajuda ao Claude** — o tipo de prompt apropriado

> **Recomendação:** faça todos os desafios em **um único projeto fictício** que você vai construir do zero, em sequência. No final, você terá um app real funcionando — sua primeira aplicação inteira construída com a metodologia.
>
> **Sugestão de projeto:** "TaskShare" — um app onde times pequenos compartilham listas de tarefas com prazos e atribuição. Simples o suficiente para terminar; complexo o suficiente para passar por todas as fases.

---

## Parte 2 — Fundamentos

### Desafio 1 — Sua primeira FONTE_DA_VERDADE

#### Cenário
Você decidiu construir o **TaskShare** (ou um projeto seu). Antes de qualquer linha de código, você vai escrever o documento master que vai guiar todo o resto.

#### O que você vai aprender
- Como definir escopo de produto sem ambiguidade
- A diferença entre "o que faz" e "o que NÃO faz"
- Como antecipar perguntas que viriam no FAQ
- Como congelar a stack com justificativas

#### Tarefa
Crie um arquivo `docs/FONTE_DA_VERDADE.md` no seu projeto com **todas** as 12 seções do template do `PROMPT_ARCHITECTURE.md` §3.1, preenchidas para o seu produto.

Mínimos por seção:
- §4 Regras de negócio: pelo menos **3 entidades** com validações, transições e edge cases
- §6 Fluxos: pelo menos **1 happy path** e **2 sad paths**
- §10 Decisões registradas: pelo menos **5 decisões** com alternativas rejeitadas
- §11 FAQ: pelo menos **8 perguntas** respondidas

#### Critérios de sucesso
- [ ] Outra pessoa lê o doc e consegue descrever o produto em 1 frase
- [ ] Não há "TBD" ou "a definir" em nenhuma regra de negócio
- [ ] Cada item da stack tem justificativa (não basta "porque é popular")
- [ ] FAQ antecipa pelo menos 3 perguntas que Claude provavelmente faria
- [ ] Existe seção "Não usar" com tecnologias proibidas

#### Armadilhas comuns
- **Escrever o que você quer construir, não o que o usuário precisa.** Reescreva começando por "o usuário X tem o problema Y..."
- **Stack baseada em hype.** Se você não sabe justificar, é hype.
- **FAQ vago.** "Como tratar autenticação?" não é pergunta — é categoria. Seja específico: "Aceitamos magic link sem senha?"
- **Pular o "Não usar".** Sem isso, Claude vai propor React em projeto que não precisa.

#### Quando pedir ajuda ao Claude
Use Opus (`/model` → Opus) e prompte:
```
Estou escrevendo a FONTE_DA_VERDADE para meu projeto {{X}}.
Aqui está o rascunho: [cole o doc].

Faça 3 coisas:
1. Liste 5 lacunas — coisas que um dev precisaria perguntar para implementar
2. Liste 3 decisões implícitas que deveriam estar explícitas
3. Sugira 5 perguntas para o FAQ

Não escreva o doc por mim — só aponte os buracos.
```

---

### Desafio 2 — Estruturando o ROADMAP_TECNICO

#### Cenário
Você já tem a `FONTE_DA_VERDADE`. Agora precisa quebrar a construção em tarefas pequenas, ordenadas por dependência, cada uma com prompt pronto para colar no Claude.

#### O que você vai aprender
- Como decompor produto em tarefas atômicas
- Como identificar dependências (o que precisa do que)
- Como escrever prompts atômicos com âncora a doc
- Como estimar complexidade (B/M/A)

#### Tarefa
Crie `docs/ROADMAP_TECNICO.md` com:

1. **Pelo menos 6 fases** (Setup, DB, Auth, Backend, Frontend, Polish)
2. **Pelo menos 25 tarefas** distribuídas pelas fases
3. Cada tarefa com: complexidade, dependências, entregável, prompt pronto
4. Mapa visual de dependências (ASCII)
5. Estimativa total em horas

Use os templates do `PROMPT_ARCHITECTURE.md` §3.5.

#### Critérios de sucesso
- [ ] Cada tarefa tem prompt **pronto para colar** no Claude (sem placeholder)
- [ ] Cada prompt cita pelo menos **uma seção** de outro doc (FONTE, ARQUITETURA, BANCO)
- [ ] A ordem respeita: schema → model → service → controller → view
- [ ] Mapa de dependências revela **caminho crítico** (quais tarefas atrasam tudo)
- [ ] Soma de complexidades = soma das estimativas (sanity check)

#### Armadilhas comuns
- **Tarefas grandes demais.** Se uma tarefa demora >3h, divida.
- **Prompts vagos.** "Implemente o auth" → vai virar 30 arquivos. Seja específico.
- **Esquecer dependências.** Service sem o model dele = refator garantido.
- **Não citar outros docs.** Sem âncora, Claude inventa.

#### Quando pedir ajuda ao Claude
```
Tenho a FONTE_DA_VERDADE pronta (./docs/FONTE_DA_VERDADE.md).
Preciso quebrar a implementação em tarefas atômicas para o ROADMAP.

Faça:
1. Liste todas as entidades e o que cada uma precisa (model, migration, service, controller, view)
2. Sugira uma ordem de implementação respeitando dependências
3. Para cada tarefa, indique se é B/M/A

Não escreva o ROADMAP — só me dê a base ordenada.
```

---

### Desafio 3 — O CLAUDE.md correto

#### Cenário
Você vai começar a programar amanhã. Toda sessão do Claude Code lê o `CLAUDE.md` da raiz automaticamente. Esse arquivo é a sua chance de não repetir as mesmas instruções 50 vezes.

#### O que você vai aprender
- O que vai no `CLAUDE.md` vs nos docs canônicos
- Como escrever instruções permanentes que economizam tokens
- A diferença entre "convenção" e "proibição"

#### Tarefa
Crie `CLAUDE.md` na raiz do projeto com:

1. **Stack em 1 linha**
2. **Caminhos de todos os docs canônicos**
3. **5+ comandos comuns** (instalar, testar, lint, dev, migrations)
4. **3+ convenções** (idioma de commits, naming, comentários)
5. **3+ proibições explícitas** ("NUNCA fazer X")
6. **Política de "quando em dúvida"**

Use o template do `PROMPT_ARCHITECTURE.md` §3.7.

#### Critérios de sucesso
- [ ] Total < 200 linhas (atalhos, não tutorial)
- [ ] Toda proibição tem motivo claro
- [ ] Comandos são copiáveis e funcionais
- [ ] Não duplica conteúdo dos docs canônicos — só linka

#### Armadilhas comuns
- **Tentar explicar o produto no CLAUDE.md.** Não — isso fica em `FONTE_DA_VERDADE`. CLAUDE.md é índice + atalhos.
- **Esquecer comandos críticos.** Se você precisa Google "como rodar testes" depois de 2 semanas longe, faltou no CLAUDE.md.
- **Vagueza nas proibições.** "Não faça código ruim" não ajuda. "Nunca rode `db:reset` em staging" sim.

#### Quando pedir ajuda ao Claude
```
Aqui está meu CLAUDE.md atual: [cole].
E aqui está minha FONTE_DA_VERDADE: [cole].

Identifique:
1. O que está no CLAUDE.md que deveria estar nos docs canônicos
2. O que está nos docs que mereceria atalho no CLAUDE.md
3. Comandos comuns do meu stack que faltam
```

---

### Desafio 4 — Setup colaborativo com Claude

#### Cenário
Você tem todos os docs prontos. Hora de criar o projeto, instalar dependências e ter "Hello World" rodando. Toda essa fase é executada pelo Claude — você orquestra.

#### O que você vai aprender
- Como abrir uma sessão produtiva
- Como pedir setup sem deixar Claude "improvisar"
- Como usar `git status` e `git diff` para verificar
- O ritual de commit por tarefa

#### Tarefa
Numa sessão nova do Claude Code:

1. Faça o **prompt de abertura** referenciando os docs (§5.1 do PROMPT_ARCHITECTURE)
2. Peça implementação da **Fase 0 inteira** do seu ROADMAP — uma tarefa por vez
3. Após cada tarefa: `git status` + `git diff --stat` → revisão → commit atômico
4. Ao final, push para um repositório (Github)

#### Critérios de sucesso
- [ ] Cada tarefa = 1 commit (não bundle)
- [ ] Mensagens de commit no padrão `tipo: descrição`
- [ ] Você leu o diff de **todos** os commits antes de aceitar
- [ ] Projeto roda localmente (servidor levanta, banco conecta, "hello" aparece)
- [ ] `.gitignore` não deixa escapar `.env` ou afins

#### Armadilhas comuns
- **Aceitar "implementei tudo" sem ver o diff.** Sempre veja.
- **Deixar Claude bundlar tarefas.** "Aproveitando..." → freie.
- **Commitar `.env` com chaves de teste.** Mesmo se for sandbox, vira hábito ruim.
- **Não rodar localmente entre commits.** Bug acumulado fica caro.

#### Quando pedir ajuda ao Claude
Você já está usando — esse desafio inteiro é "como fazer". O prompt típico:
```
Tarefa: ROADMAP §0.2 (criar projeto Rails).
Restrições:
- Só essa tarefa
- Sem migrations ainda (vem em 1.1)
- Mostre git status + git diff --stat antes de eu aprovar commit
```

---

## Parte 3 — Implementação

### Desafio 5 — Banco de dados sem voltar atrás

#### Cenário
A pior dívida técnica de um projeto vem de schema mal feito. Trocar tipo de PK depois é dor. Adicionar índice depois é janela de degradação. Você vai criar o schema **inteiro** antes de qualquer model.

#### O que você vai aprender
- Como decidir UUID vs bigint cedo
- Como justificar **cada** índice
- Quando usar check constraint vs validação Ruby/Python
- Como evitar migrations destrutivas no futuro

#### Tarefa
Crie `docs/BANCO_DE_DADOS.md` (template em PROMPT_ARCHITECTURE §3.3) e implemente:

1. Migration de extensões necessárias (UUID, etc.)
2. **Todas** as migrations de criação de tabela em ordem de dependência
3. Para cada tabela: índices justificados + check constraints + FKs
4. Seeds com pelo menos 1 registro de cada role
5. ERD em ASCII no doc

#### Critérios de sucesso
- [ ] Cada índice tem comentário "para suportar query X"
- [ ] Cada check constraint tem equivalente em validação no model
- [ ] `db:migrate` + `db:rollback` + `db:migrate` funciona em loop
- [ ] Seeds são **idempotentes** (rodar 2x não duplica)
- [ ] Se o projeto usa UUID, **PaperTrail/audit table tem `item_id` como `string`** (não bigint!)

#### Armadilhas comuns
- **Criar tabela hoje, índice "depois".** Bug de performance em 6 meses.
- **PaperTrail com PK UUID e `item_id` bigint.** Bug silencioso: `versions.item_id = 0` para tudo.
- **Check constraint só no DB.** Mensagem de erro horrível para usuário; sempre validar também no código.
- **Seeds não-idempotentes.** Quebra CI e ambientes recriados.

#### Quando pedir ajuda ao Claude
```
Tarefa: ROADMAP §1.X (migration {{nome}}).
Schema: BANCO_DE_DADOS.md §2.{{X}}.
Restrições:
- Apenas essa migration + spec do model correspondente
- Não esqueça: se PK for UUID, ajuste a tabela `versions` do PaperTrail
- Mostre o schema.rb resultante antes do commit
```

---

### Desafio 6 — Service com regra de negócio

#### Cenário
Toda lógica que cruza modelos vai em service. Aqui você vai implementar o service mais crítico do seu app — aquele que orquestra o fluxo principal (no TaskShare, seria criar uma tarefa atribuída a alguém com prazo). Ele precisa lidar com **transação**, **validação cruzada** e **race condition**.

#### O que você vai aprender
- Padrão `ApplicationService` com `Result`
- Quando usar transação + lock pessimista
- Como evitar `FOR UPDATE` + agregação (armadilha clássica)
- Por que toda service deve ser **idempotente** quando possível

#### Tarefa
Implemente um service que:
1. Recebe parâmetros (não `current_user` direto — passa como argumento)
2. Abre transação
3. Faz `lock!` em recursos disputados
4. Valida invariantes que cruzam tabelas
5. Cria/atualiza registros
6. Retorna `Result(success?, value, error)`
7. Rollback automático em qualquer falha

Cobertura de teste mínima:
- Happy path
- Falha de validação
- Race condition simulada (segundo lock falha)
- Rollback total quando algo falha no meio

#### Critérios de sucesso
- [ ] Service não conhece `current_user` — recebe como argumento
- [ ] Transação envolve **todas** as escritas relacionadas
- [ ] Em caso de race, o segundo chamador recebe erro específico (não 500)
- [ ] Spec cobre rollback (banco volta ao estado anterior se falha)
- [ ] Sem `Model.lock(...).count` ou `.size` (use `.load` antes)

#### Armadilhas comuns
- **`Model.lock("FOR UPDATE").size`** — gera `COUNT(*) FOR UPDATE`, Postgres rejeita. Use `.load` antes.
- **Service que chama `current_user`** — vira pesadelo de testar.
- **Rollback incompleto** — esquecer um `update!` fora da transação.
- **Idempotência ignorada** — chamar 2x cria 2 registros (devia ser no-op).

#### Quando pedir ajuda ao Claude
```
Tarefa: ROADMAP §X.Y (BookingCreator service).
Regra: FONTE_DA_VERDADE §4.4 (criação de booking).
Schema: BANCO_DE_DADOS.md §2.5.

Implemente:
- app/services/application_service.rb (base com .call)
- app/services/booking_creator.rb
- spec/services/booking_creator_spec.rb cobrindo: happy + race + rollback

Restrições:
- NÃO acesse current_user dentro do service
- Use transação + lock!
- Atenção: NÃO chame .count ou .size em relation com FOR UPDATE — use .load
- Retorne Result com .success?, .value, .error
```

---

### Desafio 7 — Integração externa robusta

#### Cenário
Seu app precisa falar com um sistema externo (gateway de pagamento, serviço de email transacional, API de mapas). Toda integração externa traz: timeout, dado inválido, webhook duplicado, mudança de schema da API. Você vai implementar isso direito.

#### O que você vai aprender
- Padrão de service para integração (1 por endpoint)
- Como mockar **só** no boundary (não no service interno)
- Validação de webhook (HMAC)
- Idempotência em handlers de webhook

#### Tarefa
Implemente integração com um serviço externo (escolha um: Stripe sandbox, MercadoPago sandbox, SendGrid, ou um serviço fictício com WebMock).

Entregáveis:
1. Service que **chama** a API externa (`Service::Caller`)
2. Service que **busca** dados (`Service::Finder`)
3. Service que **valida** webhook recebido (`Service::WebhookValidator` com HMAC)
4. Controller de webhook idempotente
5. Specs com mock no nível HTTP (WebMock ou equivalente) — **não** mockar o service interno

#### Critérios de sucesso
- [ ] Mocks **somente** em chamadas HTTP — services internos rodam de verdade nos testes
- [ ] Webhook duplicado: 2ª chamada é no-op (sem efeito colateral)
- [ ] Webhook com assinatura inválida: retorna 401
- [ ] Há flag/secret para **bypass de validação em dev** (ex: secret prefixado com `mock-`)
- [ ] Logs detalhados quando a API externa falha (ajuda em prod)

#### Armadilhas comuns
- **Mockar service interno.** Testa o mock, não o código. Sempre mocke no boundary HTTP.
- **Webhook sem HMAC.** Qualquer um pode marcar pagamento como confirmado.
- **Sem idempotência.** Webhook chega 3x → cria 3 registros.
- **Sem bypass em dev.** Toda vez que rodar local, precisa ngrok + assinatura real.
- **Esquecer logs.** Quando a integração falhar em prod, você vai querer rastreio.

#### Quando pedir ajuda ao Claude
```
Tarefa: ROADMAP §X.Y (integração com {{API}}).
Regra: FONTE_DA_VERDADE §X.

Implemente em app/services/{{provider}}/:
- caller.rb (cria recurso na API)
- finder.rb (busca recurso)
- webhook_validator.rb (HMAC SHA256)

Controller: app/controllers/webhooks/{{provider}}_controller.rb (idempotente).

Specs com WebMock — NÃO mocke as services internas, só as chamadas HTTP.
Inclua bypass: se ENV['{{PROVIDER}}_SECRET'] começa com 'mock-', validador retorna true sem checar.
```

---

### Desafio 8 — Suite de testes que importa

#### Cenário
Testes ruins dão **falsa segurança**. Testes bons pegam regressões reais. Você vai construir uma suite que cobre o que **importa** — sem virar ritual.

#### O que você vai aprender
- Pirâmide de testes (model > service > request > system)
- Quando vale system test e quando é desperdício
- Como evitar testes flaky (PaperTrail, RequestStore, transação)
- Como medir cobertura sem virar refém

#### Tarefa
Para o seu app, garanta:

1. **Model spec** para toda transição de estado (`confirm!`, `cancel!`, `expire!`)
2. **Service spec** para toda service (happy + sad + idempotência)
3. **Request spec** para webhook + 1-2 fluxos críticos
4. **Configuração de boundary** — PaperTrail só ativo com `versioning: true`, mocks externos via WebMock
5. CI rodando todos os specs automaticamente

#### Critérios de sucesso
- [ ] `bundle exec rspec` passa em < 60s no projeto inteiro
- [ ] Zero teste flaky (rode 5x seguidas — todas passam)
- [ ] Cobertura mínima de transições de estado: **100%**
- [ ] Sem `sleep` em testes (usa stubs de tempo: `Timecop`, `freeze_time`)
- [ ] Specs de webhook não dependem de internet

#### Armadilhas comuns
- **PaperTrail flaky no RSpec.** Solução: `require "paper_trail/frameworks/rspec"` + tag `versioning: true` em testes específicos.
- **`Timecop` não resetado entre testes.** Use `Timecop.return` em `after`.
- **Factory com `created_at` no passado dispara validação de "futuro obrigatório".** Use `build`, não `create`, e ajuste.
- **Service spec mockando AR.** Não — deixe AR rodar. Mocke só HTTP/SMTP/push.
- **System spec lento.** Reserve para 2-3 fluxos golden — não use para tudo.

#### Quando pedir ajuda ao Claude
```
Tarefa: cobrir com specs o {{Model/Service}}.
Convenções: ARQUITETURA.md §9 (estrutura de testes).

Implemente specs cobrindo:
1. Cada transição de estado documentada na FONTE_DA_VERDADE §4.X
2. Happy path + 2 sad paths
3. Race condition (se aplicável)

NÃO mocke models, NÃO mocke services internos.
Mocks SOMENTE em chamadas HTTP via WebMock.
Use FactoryBot traits para variantes.
```

---

### Desafio 9 — CRUD bem feito

#### Cenário
A maior parte de um app é CRUD. CRUD ruim consome 80% do código de manutenção. Você vai implementar o CRUD admin do recurso mais importante do seu app — com paginação, filtros, autorização, audit log, e respeitando convenções de pasta.

#### O que você vai aprender
- Estrutura de namespace admin
- Pundit / autorização por scope
- Filtros em URL com query string segura
- Paginação sem N+1
- Como mostrar audit log de forma útil

#### Tarefa
Implemente CRUD admin de **uma** entidade do seu app:

1. Controller em `app/controllers/admin/` com 5 actions REST + 1 custom (`cancel`, `archive`, etc.)
2. Policy Pundit (ou equivalente) com scope multi-tenant
3. Views: `index` (com filtros + paginação), `show`, `new/edit` com partial `_form`, `_versions_table` (audit)
4. Strong params **não** permite campo sensível (ex: `email`, `role`, `id`)
5. Spec de request: index com filtro, create, update, destroy, autorização

#### Critérios de sucesso
- [ ] `index` faz **uma** query principal + includes (sem N+1)
- [ ] Filtros por query string são parametrizados (sem SQL injection)
- [ ] Usuário sem permissão recebe 403, não 500
- [ ] `destroy` é soft-delete se a entidade é referenciada por FK em outras tabelas
- [ ] Audit log é visível e legível na view de show
- [ ] Paginação funciona com pagy/kaminari, sem `LIMIT N, OFFSET M` em datasets grandes

#### Armadilhas comuns
- **N+1 no index.** Adicione `.includes(...)` desde o primeiro dia.
- **Strong params permitindo `:role` por engano.** Escalonamento de privilégio.
- **Filtro `where("name LIKE '%#{params[:q]}%'")`.** SQL injection. Use bind: `where("name ILIKE ?", "%#{params[:q]}%")`.
- **Hard-delete de entidade referenciada.** Quebra FK em registros antigos.

#### Quando pedir ajuda ao Claude
```
Tarefa: CRUD admin de {{Entidade}}.
Convenções: ARQUITETURA.md §3 (camadas).
Schema: BANCO_DE_DADOS.md §2.X.
Policy: Pundit, scope filtra por current_user.clinic_id.

Implemente:
- app/controllers/admin/{{entidades}}_controller.rb (5 RESTful)
- app/policies/{{entidade}}_policy.rb
- app/views/admin/{{entidades}}/index|show|new|edit + _form + _versions_table
- spec/requests/admin/{{entidades}}_spec.rb

Restrições:
- Strong params NÃO permite: id, role, criado_em
- Index com paginação (pagy) e includes para evitar N+1
- destroy é soft (active: false) se houver FK
- Audit visível em show
```

---

## Parte 4 — Operação

### Desafio 10 — CI que pega bugs

#### Cenário
CI ruim demora minutos, falha intermitentemente, e o time aprende a ignorar. CI bom é rápido, determinístico, e bloqueia merge quando algo importante quebra. Você vai configurar GitHub Actions que vale o tempo que toma.

#### O que você vai aprender
- Quais jobs valem a pena ter (lint, security scan, testes, build)
- Como configurar serviços (Postgres, Redis) no CI
- Variáveis de ambiente em CI sem vazar segredo
- Badge de status no README

#### Tarefa
Crie `.github/workflows/ci.yml` rodando em PR e push para `main`:

1. Job de **lint** (RuboCop, ESLint, etc.)
2. Job de **security scan** (Brakeman, npm audit)
3. Job de **testes** com Postgres + Redis como serviços
4. Variáveis mock para API externa (`MERCADOPAGO_ACCESS_TOKEN: TEST-000...`)
5. Cache de dependências (bundler-cache, npm cache)
6. Badge no README

#### Critérios de sucesso
- [ ] CI completo roda em < 5min
- [ ] Falha de lint bloqueia merge
- [ ] Falha de teste bloqueia merge
- [ ] Sem segredo real em código (todos via `secrets.X` do GitHub)
- [ ] Badge no README mostra status atual

#### Armadilhas comuns
- **CI sem cache.** Bundler instala tudo do zero a cada commit — desperdício.
- **Job único enorme.** Lint demora 30s; teste 3min. Separar em jobs paralelos economiza tempo.
- **Banco sem health check.** Teste tenta conectar antes do Postgres responder → flaky.
- **Mock token real comitado.** Mesmo sandbox vira hábito perigoso. Use prefixo `TEST-` ou `mock-`.

#### Quando pedir ajuda ao Claude
```
Configure GitHub Actions para o projeto.

Stack: {{X}}.

Crie .github/workflows/ci.yml com 4 jobs em paralelo:
1. lint
2. security_scan (Brakeman + audit)
3. test (Postgres 16 + Redis 7 como services, com health checks)
4. build (se aplicável)

Variáveis de ambiente:
- DATABASE_URL apontando para o serviço Postgres do CI
- REDIS_URL idem
- {{API}}_ACCESS_TOKEN: 'TEST-000...' (mock)
- SECRET_KEY_BASE gerado no job

Após criar, me dê o trecho de README para o badge.
```

---

### Desafio 11 — Deploy + smoke test

#### Cenário
Tem código rodando local + CI verde, mas produção é outra coisa. Você vai colocar o app no ar, verificar que tudo funciona, e ter um smoke test que roda na sua frente.

#### O que você vai aprender
- Escolher plataforma (Railway, Render, Fly, VPS com Docker)
- Variáveis de ambiente em produção
- Migrations + seed em ambiente novo
- Webhook configurado para apontar para produção
- Smoke test manual estruturado

#### Tarefa
Faça deploy do seu app em produção (ou staging real, com domínio):

1. Plataforma escolhida + justificativa em `CONTEXT.md`
2. Variáveis de ambiente configuradas (sem `.env` no servidor)
3. Migrations rodadas + seed mínimo
4. HTTPS funcionando (certificado válido)
5. Webhook configurado no provedor externo apontando para `https://...`
6. **Smoke test manual** documentado em `docs/SMOKE_TEST.md`:
   - Lista numerada de passos
   - Ações + resultado esperado por passo
   - Pelo menos 1 fluxo completo end-to-end

#### Critérios de sucesso
- [ ] Você consegue fazer login no app em produção
- [ ] Você executa o fluxo principal (criar reserva, enviar tarefa, etc.) sem erro
- [ ] Webhook do provedor chega e é processado
- [ ] Logs visíveis (você sabe onde olhar quando der ruim)
- [ ] `SMOKE_TEST.md` é executável por outra pessoa

#### Armadilhas comuns
- **Variáveis de ambiente esquecidas.** App levanta mas crasha em qualquer ação que precise da var.
- **Webhook configurado para `localhost`.** Provedor envia, ninguém recebe.
- **Banco vazio em produção.** Sem owner inicial, ninguém entra.
- **Sem HTTPS.** Webhooks de provedores sérios recusam.
- **Não rodar o smoke test manual.** "Tá no ar" ≠ "funciona".

#### Quando pedir ajuda ao Claude
```
Tenho meu app pronto e CI verde. Quero deploy em {{plataforma}}.

Faça:
1. Liste todas as variáveis de ambiente que preciso configurar (saindo de .env.example)
2. Liste o passo-a-passo do deploy (build, migrations, seed, restart)
3. Crie docs/SMOKE_TEST.md com os 5 fluxos críticos a testar manualmente após cada deploy

NÃO faça o deploy por mim — só me dê a checklist.
```

---

### Desafio 12 — Manutenção e evolução

#### Cenário
App está em produção há 2 semanas. Você descobriu 3 bugs, recebeu 2 pedidos de feature, e quer adicionar uma nova regra. Como manter o ritmo sem virar bagunça?

#### O que você vai aprender
- Workflow de manutenção (issue → branch → PR → merge → deploy)
- Quando atualizar `FONTE_DA_VERDADE` vs `CONTEXT`
- Como retomar o projeto depois de pausa de semanas
- Como evoluir feature sem quebrar produção

#### Tarefa
Simule o ciclo de manutenção completo:

1. **Bug fix** — descubra um bug real no seu app, abra issue no Github, crie branch, fix com teste de regressão, PR, merge
2. **Nova feature** — adicione algo novo:
   - Atualize `FONTE_DA_VERDADE.md` PRIMEIRO (regra de negócio nova)
   - Adicione tarefa em `ATIVIDADES.md`
   - Implemente via tarefa atômica
   - Atualize `CONTEXT.md` se aprendeu algo
3. **Pause por 1 semana** (real ou simulado)
4. **Retome em sessão nova** — execute o ritual de abertura (§7 do PROMPT_ARCHITECTURE)

#### Critérios de sucesso
- [ ] Bug fix tem teste de regressão (que falharia antes do fix)
- [ ] Feature nova começa por **doc**, não por código
- [ ] Você consegue retomar em < 10min após 1 semana de pausa
- [ ] `ATIVIDADES.md` reflete o estado real
- [ ] `CONTEXT.md` ganhou pelo menos 1 entrada nova

#### Armadilhas comuns
- **Fix sem teste de regressão.** Volta em 3 meses.
- **Feature implementada sem atualizar `FONTE_DA_VERDADE`.** Doc fica mentindo.
- **Não atualizar `ATIVIDADES.md`.** Você esquece o que estava fazendo.
- **Fazer commit "wip" antes de pausar.** Nunca volte com seu código quebrado.

#### Quando pedir ajuda ao Claude
```
Estou retomando o projeto após 1 semana parado.

Faça:
1. Leia ATIVIDADES.md e me liste as 3 tarefas mais prioritárias
2. Leia CONTEXT.md e me lembre das 3 decisões mais importantes
3. Rode `git log --oneline -10` e me explique onde estávamos
4. Sugira por onde começar hoje
```

---

## Parte 5 — Maestria

### 5.1 Como saber que você dominou o método

Você dominou quando:

- ✅ Consegue iniciar projeto novo e ter doc canônica em 1 dia
- ✅ Não escreve mais código antes de seção do doc estar fechada
- ✅ Sessão nova começa em < 5min com ritual automático
- ✅ Backlog (`ATIVIDADES.md`) é fonte da verdade do "o que falta", não sua memória
- ✅ Bug em produção raramente é "não documentado" — quase sempre é "não testado"
- ✅ Você consegue parar 2 semanas e voltar sem perder ritmo

### 5.2 Próximos passos

- **Aplicar em projeto comercial real** com stakes maiores
- **Compartilhar a metodologia** com outro dev e ver onde a sua doc tem buracos
- **Construir templates próprios** — seus docs viram boilerplate para projetos futuros
- **Contribuir** — sua versão melhorada do `PROMPT_ARCHITECTURE.md` pode ajudar outros

### 5.3 Quando o método **não** funciona

Esse método é caro em frente: 1-2 dias de doc antes do código. Não use quando:

- O projeto é uma **prova de conceito** descartável (1-2 dias de vida)
- O escopo é **muito incerto** (pesquisa pura)
- Você está **explorando uma tecnologia nova** e o objetivo é aprender, não entregar

Para esses, vá direto ao código. Mas qualquer coisa que vai durar >1 mês ou vai ter usuário real, **vale o investimento em doc**.

---

## Apêndice — Mapa de skills

Cada desafio cobre skills específicas. Use a tabela para identificar lacunas:

| Skill | Desafios que treinam |
|---|---|
| Definir escopo de produto | 1 |
| Decompor em tarefas atômicas | 2 |
| Escrever prompt eficaz | 2, 4, 5-12 |
| Ritual de sessão | 4, 12 |
| Schema design | 5 |
| Lock + transação | 6 |
| Service pattern | 6, 7 |
| Integração externa | 7 |
| Mock no boundary | 7, 8 |
| Test pyramid | 8 |
| Pundit / autorização | 9 |
| CRUD admin | 9 |
| CI/CD | 10 |
| Deploy + smoke test | 11 |
| Workflow de manutenção | 12 |

---

> **Frase guia:** o dev solo bem-sucedido com Claude Code não é o que digita mais rápido — é o que **decide melhor** e **documenta antes**.
