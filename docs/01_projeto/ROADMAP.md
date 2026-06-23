# Roadmap — De Júnior a Tech Senior

> Roadmap de evolução de carreira usando o **Videira Dental como veículo de aprendizado**.
> Cada fase tem: competências, atividades práticas **neste projeto** e critério de conclusão.
> O roadmap original de construção do MVP foi concluído — está arquivado em `ROADMAP_TECNICO.md`.
> Última atualização: 2026-06-10

---

## Como usar

- As fases são cumulativas — não pule; um senior é um pleno que não esqueceu o básico.
- Cada atividade prática aponta para código **real** deste projeto. Aprender resolvendo problema de verdade fixa 10x mais que tutorial.
- Marque `[x]` quando cumprir o **critério de conclusão**, não quando "achar que entendeu".
- Ritmo realista: **12–24 meses** dedicando-se de forma consistente.

---

## Fase 0 — Inventário: o que o projeto já prova que você sabe

Antes de olhar para frente, reconheça o que já foi construído aqui (e saiba **explicar** cada item — explicar é o que separa "fiz" de "sei"):

- [ ] MVP Rails fullstack completo em produção-ready: agendamento, carrinho, checkout em lote, pagamento Pix, créditos, recarga, admin.
- [ ] Concorrência: explicar de memória por que o checkout usa `lock!` (FOR UPDATE) **e** índice único parcial em `bookings.availability_id` (defesa em duas camadas).
- [ ] Integração com gateway externo (InfinitePay): checkout hospedado, webhook, fallback de consulta (`PaymentChecker`), idempotência.
- [ ] Suite de testes (148 exemplos: models, services, requests, system) + CI com 4 jobs (Brakeman, importmap audit, RuboCop, RSpec).
- [ ] Dinheiro em centavos, enums string com check constraints, UUIDs — e o porquê de cada decisão (ver `BANCO_DE_DADOS.md §4`).

**Critério de conclusão da fase:** conseguir apresentar a arquitetura do projeto em 15 minutos para outro dev, sem olhar os docs, respondendo "por quê?" em cada camada.

---

## Fase 1 — Pleno: Confiabilidade (feche os gaps reais do projeto)

A diferença entre júnior e pleno: o júnior faz funcionar no caminho feliz; o pleno pensa em **tudo que pode dar errado**. Este projeto tem gaps reais documentados — use-os como exercício.

### 1.1 Endurecer o webhook de pagamento 🔴
- [ ] Comparar `paid_amount` do webhook com `payment.amount_cents` antes de confirmar (hoje qualquer `paid_amount > 0` confirma o grupo inteiro).
- [ ] Confirmar via `InfinitePay::PaymentChecker` (server-to-server) antes de marcar como pago, em vez de confiar no payload recebido.
- [ ] Escrever os request specs dos cenários de abuso: valor parcial, `order_nsu` alheio, payload malformado.

**O que você aprende:** nunca confiar em entrada externa; a diferença entre autenticação de origem e validação de conteúdo.

### 1.2 Completar o ciclo de vida de `CreditPurchase` 🟡
- [ ] `ExpirePaymentsJob` (ou job próprio) expira recargas pendentes vencidas.
- [ ] Adicionar check constraint em `credit_purchases.status` (única tabela sem).

**O que você aprende:** todo estado `pending` precisa de um caminho de saída automático; consistência de schema é disciplina, não estética.

### 1.3 Testes que dão confiança de verdade
- [ ] Adicionar `selenium-webdriver` e fazer ao menos 2 system specs `js: true` rodarem (calendário e carrinho usam Stimulus — hoje nada testa o JS).
- [ ] Medir cobertura com SimpleCov e identificar os 3 fluxos críticos menos cobertos.
- [ ] Escrever um teste de concorrência real para `BookingGroupCreator` (duas threads disputando o mesmo slot).

**Critério de conclusão da fase:** os 3 gaps acima resolvidos, com testes, e você consegue explicar cada cenário de falha que eles previnem.

---

## Fase 2 — Pleno avançado: Operar em produção

Senior não é quem escreve código bonito — é quem **dorme tranquilo com o sistema no ar**. Esta fase só se aprende com o app rodando de verdade.

### 2.1 Deploy real
- [x] Fazer o deploy completo na Railway (go-live 2026-06; o README e o `docs/05_setup/DEPLOY_PRODUCAO.md` documentam o passo a passo).
- [ ] Provocar e executar um rollback de verdade (redeploy de uma versão anterior pelo painel da Railway).
- [x] Deploy automático no push para `main` (Railway conectada ao GitHub).

### 2.2 Backups e recuperação
- [ ] Automatizar `pg_dump` diário + cópia do volume do Active Storage para fora da VPS.
- [ ] **Testar a restauração** num banco limpo (backup não testado não é backup).
- [ ] Documentar o procedimento num runbook curto (tempo de recuperação esperado).

### 2.3 Observabilidade
- [ ] Error tracking (Sentry/Honeybadger — free tier serve): saber de erro **antes** do usuário reclamar.
- [ ] Logs estruturados nos services de pagamento (request id, order_nsu, duração) — hoje há `Rails.logger.error` esparso.
- [ ] Uptime check externo no `/up` + alerta.
- [ ] Painel mínimo de métricas de negócio: pagamentos confirmados/expirados por dia, tempo entre criação e confirmação (o webhook está chegando? o job está rodando?).

### 2.4 Resposta a incidente
- [ ] Simular: Sidekiq parado por 2h → reservas presas em pending. Detectar pelo monitoramento, corrigir, escrever um post-mortem de 1 página (o que falhou, como detectamos, como prevenir).

**Critério de conclusão da fase:** o app em produção, com backup testado, e você descobrindo um erro pelo alerta antes de qualquer usuário avisar.

---

## Fase 3 — Senior: Segurança e Performance

### 3.1 Segurança
- [ ] Rate limiting (`rack-attack`): login, webhook e criação de recarga.
- [ ] Auditoria de autorização: mapear cada rota → quem pode acessar. O admin confia no `require_owner!`; verifique se nenhum recurso vaza entre clínicas ou entre dentistas (ex.: `policy_scope` em todas as listagens do dentista).
- [ ] Tratar os achados do Brakeman que hoje passam despercebidos no CI (ler o relatório, não só o exit code).
- [ ] Revisar o fluxo de recarga contra abuso: valores extremos, spam de `CreditPurchase` pendente.

### 3.2 Performance
- [ ] Instalar `bullet` em dev e eliminar N+1 nas listagens (admin/bookings e dashboard são candidatos).
- [ ] `EXPLAIN ANALYZE` nas 3 queries mais pesadas (dashboard de receita, saldo de créditos, agenda do dia) e decidir se precisam de índice.
- [ ] Caching: fragment cache nos cards da home (slots do dia) e medir antes/depois.
- [ ] Load test simples (k6 ou `ab`) no fluxo de checkout: descobrir o limite atual e **onde** quebra primeiro.

**O que você aprende:** otimizar com dados, não com intuição. Senior mede antes de mexer.

**Critério de conclusão da fase:** um documento curto com números: requests/s suportados, queries otimizadas (tempo antes/depois), achados de segurança fechados.

---

## Fase 4 — Senior: Arquitetura e decisões

Aqui a pergunta muda de "como implemento?" para "**devo** implementar? a que custo? qual alternativa?".

### 4.1 Registrar decisões como um senior
- [ ] Adotar ADRs leves: toda decisão arquitetural nova ganha entrada em `ATIVIDADES_DECISOES.md` (contexto → opções → decisão → consequências). Você já tem o histórico de InfinitePay vs MercadoPago para reescrever nesse formato como exercício.

### 4.2 Evoluções com trade-off real (escolha 2, justifique por escrito antes de codar)
- [ ] **Multi-tenant de verdade:** evoluir `Current.clinic` para resolução por subdomínio/slug. Mapear cada query que depende de `Clinic.first` e o risco de vazamento entre tenants.
- [ ] **Crédito proporcional:** emitir crédito parcial quando 1 de N reservas pagas é cancelada (pendência registrada em `ATIVIDADES.md`). Envolve aritmética de rateio em centavos — onde vão os centavos que sobram?
- [ ] **Google Agenda:** implementar a integração desenhada no README (refresh token, `EventCreator`/`EventRemover`, hooks em confirmer/canceller). Primeiro contato com OAuth offline + API de terceiro com quota.
- [ ] **Outbox/retry de webhooks:** o que acontece se o broadcast ou o mailer falham depois do `update!`? Estudar o padrão transactional outbox e decidir se o projeto precisa (provavelmente não — saber dizer **não** também é arquitetura).

### 4.3 Template AgendaKit
- [ ] Extrair o que é genérico (agendamento + checkout em lote + créditos) do que é Videira (marca, regras). Documentar o corte. É o exercício de **abstração na hora certa** — depois de 1 caso real, não antes.

**Critério de conclusão da fase:** 2 evoluções entregues com ADR escrito antes da implementação, e 1 proposta **recusada** com justificativa técnica (saber não fazer).

---

## Fase 5 — Tech Senior: Multiplicar (não só executar)

Tech senior é medido pelo impacto **além do próprio código**:

- [ ] **Code review de qualidade:** revisar PRs (seus próprios, com olhar de outro dev, ou de terceiros em open source) apontando riscos de produção, não estilo.
- [ ] **Documentação viva:** manter o ciclo que começou aqui — docs auditados contra o código (este repo é seu portfólio de como você documenta).
- [ ] **Comunicação com não-técnicos:** explicar para a dona da clínica, em linguagem de negócio, por que backups/monitoramento valem o custo mensal. Escrever a proposta.
- [ ] **Estimativa e priorização:** pegar o backlog da Fase 3–4, estimar, priorizar por risco × valor e cumprir o prazo que você mesmo deu.
- [ ] **Mentoria:** ensinar alguém (post técnico, talk, pair programming). Os documentos `JORNADA_DEV_SOLO.md` e `roadmap-subindo-local.md` já mostram vocação didática — publique.
- [ ] **Entrevistas do outro lado:** estudar system design usando este projeto como caso ("desenhe um sistema de agendamento com pagamento") — você já construiu um; saiba defendê-lo e escalá-lo no quadro branco.

**Critério de conclusão:** você consegue conduzir um projeto do zero à produção **e** elevar o nível de quem trabalha com você. Isso é tech senior.

---

## Resumo visual

```
Fase 0          Fase 1            Fase 2           Fase 3            Fase 4              Fase 5
Inventário  →   Confiabilidade →  Produção      →  Segurança +    →  Arquitetura +    →  Multiplicar
(explicar       (webhook, ciclo   (deploy, backup,  Performance       decisões (ADRs,     (review, docs,
 o que já        de vida, testes   observabilidade,  (rate limit,      multi-tenant,       comunicação,
 existe)         JS/concorrência)  incidente)        N+1, caching)     trade-offs)         mentoria)
└────────── PLENO ──────────────┘└────────────── SENIOR ───────────────┘└──── TECH SENIOR ────┘
```

---

## Conexão com o restante da documentação

| Para | Ver |
|---|---|
| Pendências técnicas concretas citadas nas fases | `ATIVIDADES_DECISOES.md` (seção de pendências) |
| Estado atual da arquitetura | `../02_arquitetura/ARQUITETURA.md` |
| Histórico do que já foi construído | `ROADMAP_TECNICO.md` (arquivado) e `ATIVIDADES.md` |
| Operação e deploy | `README.md` (raiz) |

---

*Atualize este roadmap ao concluir cada fase — e anote a data. Daqui a um ano, o diff deste arquivo é a prova do seu crescimento.*
