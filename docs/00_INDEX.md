# Videira Dental Clinic — Índice

> Mapa central do projeto. Abra este arquivo no Obsidian para navegar por toda a documentação.

---

## 01 · Projeto

| Documento | Descrição |
|-----------|-----------|
| [[FONTE_DA_VERDADE]] | Visão de produto original + tabela de divergências spec × implementação |
| [[ATIVIDADES_DECISOES]] | Auditoria 2026-06-10: decisões com motivos (ADR leve) + pendências técnicas |
| [[ATIVIDADES]] | Histórico das atividades implementadas em 2026-05 |
| [[ROADMAP]] | **Roadmap de carreira Júnior → Tech Senior** ancorado no projeto |
| [[ROADMAP_TECNICO]] | (Arquivado) roadmap de construção do MVP, concluído |
| [[CONTEXT]] | (Histórico) contexto da fase de construção |

## 02 · Arquitetura

| Documento | Descrição |
|-----------|-----------|
| [[ARQUITETURA]] | Camadas, convenções e fluxos reais (auditado 2026-06-10) |
| [[BANCO_DE_DADOS]] | Schema PostgreSQL real, espelhado de `db/schema.rb` |
| [[MODULOS]] | Mapa funcional dos 6 módulos do sistema |
| [[INFINITEPAY]] | Integração com o gateway de pagamento (API, webhook, retorno) |

## 03 · Design

| Documento | Descrição |
|-----------|-----------|
| [[README]] (em `03_design/`) | **Comece aqui** — índice e fluxo recomendado |
| [[TEMPLATE_TELA_E_MODAL]] | Esqueletos prontos para criar telas e modais novos |
| [[DESIGN_SYSTEM]] | Tokens, classes utilitárias `.btn-*`/`.card-*`/`.badge-*` e helpers Ruby |
| [[CATALOGO_TELAS]] | Mapa das telas existentes para reuso ao construir telas novas |
| [[ARCHIVE_RESTYLING]] | Histórico (arquivado) do restyling inicial — não usar como guia |

## 04 · Processo

| Documento | Descrição |
|-----------|-----------|
| [[JORNADA_DEV_SOLO]] | Guia prático de uso do Claude Code para devs solo |
| [[PROMPT_ARCHITECTURE]] | Arquitetura de documentação e prompts para projetos com IA |

## 05 · Setup

| Documento | Descrição |
|-----------|-----------|
| [[DEPLOY_PRODUCAO]] | **Produção** — hospedagem (Railway), domínio, e-mail (Resend), variáveis e diagnóstico |
| [[VSCODE_SETUP]] | Configuração completa do editor para o projeto Rails |

---

## Fluxo de leitura recomendado

```
FONTE_DA_VERDADE → ARQUITETURA → BANCO_DE_DADOS → MODULOS → INFINITEPAY
       ↓
  ATIVIDADES_DECISOES (decisões + pendências) → ROADMAP (júnior → tech senior)
       ↓
  03_design/README → TEMPLATE_TELA_E_MODAL → DESIGN_SYSTEM → CATALOGO_TELAS
```

> **README.md** (raiz do projeto) cobre setup local, OAuth, InfinitePay, SMTP e deploy na Railway.
