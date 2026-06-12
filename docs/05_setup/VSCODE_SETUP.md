# Videira Dental Clinic — VSCODE_SETUP.md
> Configuração completa do VSCode para o projeto Rails.  
> Siga do início ao fim uma única vez.

---

## 1. Extensões obrigatórias

Instale todas pelo painel de extensões do VSCode (`Ctrl+Shift+X`) ou pelo terminal:

```bash
# Colar no terminal e rodar tudo de uma vez
code --install-extension Shopify.ruby-lsp
code --install-extension misogi.ruby-rubocop
code --install-extension bradlc.vscode-tailwindcss
code --install-extension esbenp.prettier-vscode
code --install-extension mikestead.dotenv
code --install-extension GitHub.copilot
code --install-extension eamodio.gitlens
code --install-extension EditorConfig.EditorConfig
code --install-extension ms-vscode.live-server
code --install-extension humao.rest-client
code --install-extension mechatroner.rainbow-csv
code --install-extension oderwat.indent-rainbow
```

### O que cada uma faz

| Extensão | Para que serve |
|----------|---------------|
| **Ruby LSP** (Shopify) | Autocomplete, go-to-definition, hover docs para Ruby/Rails |
| **RuboCop** | Linting e formatação do Ruby em tempo real |
| **Tailwind CSS IntelliSense** | Autocomplete de classes Tailwind nas views ERB |
| **Prettier** | Formatação de JS, CSS, JSON |
| **DotENV** | Syntax highlight para arquivos `.env` |
| **GitHub Copilot** | IA inline no editor |
| **GitLens** | Git blame inline, histórico de arquivo |
| **EditorConfig** | Garante consistência de indentação/encoding |
| **REST Client** | Testar webhooks e endpoints diretamente no VSCode |
| **Rainbow CSV** | Visualização de CSVs (útil para exports) |
| **Indent Rainbow** | Identação colorida — essencial para ERB aninhado |

---

## 2. Configurações do VSCode (`settings.json`)

Abrir com `Ctrl+Shift+P` → "Open User Settings (JSON)" e adicionar:

```json
{
  // Ruby
  "[ruby]": {
    "editor.defaultFormatter": "Shopify.ruby-lsp",
    "editor.formatOnSave": true,
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },

  // ERB
  "[erb]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.wordWrap": "on"
  },

  // JavaScript
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },

  // CSS
  "[css]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  },

  // Tailwind — habilitar autocomplete em ERB e HTML
  "tailwindCSS.includeLanguages": {
    "erb": "html",
    "ruby": "html"
  },
  "tailwindCSS.experimental.classRegex": [
    ["class\\s*[=:]\\s*[\"']([^\"']*)[\"']", "([^\"']*)"]
  ],

  // Editor geral
  "editor.fontSize": 14,
  "editor.lineHeight": 1.6,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.wordWrap": "on",
  "editor.formatOnSave": true,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "editor.minimap.enabled": false,
  "editor.renderWhitespace": "boundary",

  // Terminal
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.defaultProfile.osx": "zsh",

  // Git
  "git.autofetch": true,
  "gitlens.codeLens.enabled": true,
  "gitlens.blame.compact": true,

  // Arquivos
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/tmp": true,
    "**/log": false
  },

  // Explorer
  "explorer.compactFolders": false,
  "workbench.tree.indent": 16
}
```

---

## 3. Arquivo `.editorconfig` (raiz do projeto)

Criar na raiz do projeto Rails:

```ini
# .editorconfig
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.md]
trim_trailing_whitespace = false
```

---

## 4. Arquivo `.rubocop.yml` (raiz do projeto)

Configuração mínima sem atrapalhar o desenvolvimento:

```yaml
# .rubocop.yml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3
  Exclude:
    - 'db/**/*'
    - 'config/**/*'
    - 'bin/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'

# Linha um pouco maior para Rails (padrão 120)
Layout/LineLength:
  Max: 120

# Permite métodos um pouco maiores
Metrics/MethodLength:
  Max: 20

# Não exige documentação de classes/modules
Style/Documentation:
  Enabled: false

# Permite uso de guard clauses
Style/GuardClause:
  Enabled: true

# Permite frozen_string_literal opcional
Style/FrozenStringLiteralComment:
  Enabled: false

# Rails específico
Rails:
  Enabled: true
```

---

## 5. Atalhos úteis para este projeto

| Atalho | Ação |
|--------|------|
| `Ctrl+P` | Abrir arquivo por nome (ex: `home_controller`) |
| `Ctrl+Shift+F` | Busca global no projeto |
| `Ctrl+Shift+P` | Paleta de comandos |
| `F12` | Go to definition (Ruby LSP) |
| `Alt+F12` | Peek definition |
| `Ctrl+Shift+R` | Refactoring (Ruby LSP) |
| `Ctrl+`` ` | Abrir terminal integrado |
| `Ctrl+Shift+`` ` | Novo terminal |
| `` Ctrl+K ` `` | Fechar todos os terminais |

---

## 6. Snippets personalizados para o projeto

`Ctrl+Shift+P` → "Configure User Snippets" → `ruby.json`:

```json
{
  "Rails Controller Action": {
    "prefix": "raction",
    "body": [
      "def ${1:action_name}",
      "  @${2:variable} = ${3:Model}.find(params[:id])",
      "  authorize @${2:variable}",
      "  ${0}",
      "end"
    ],
    "description": "Rails controller action com Pundit"
  },

  "Pundit Policy Method": {
    "prefix": "rpolicy",
    "body": [
      "def ${1:action_name}?",
      "  ${2:user}.owner?",
      "end"
    ],
    "description": "Pundit policy method"
  },

  "Rails Before Action": {
    "prefix": "rbefore",
    "body": [
      "before_action :${1:set_resource}, only: %i[${2:show edit update destroy}]",
      "",
      "private",
      "",
      "def ${1:set_resource}",
      "  @${3:resource} = ${4:Model}.find(params[:id])",
      "end"
    ],
    "description": "Before action + private setter"
  },

  "Turbo Frame Tag": {
    "prefix": "tframe",
    "body": [
      "<%= turbo_frame_tag \"${1:frame_id}\" do %>",
      "  ${0}",
      "<% end %>"
    ],
    "description": "Turbo Frame tag"
  },

  "Turbo Stream From": {
    "prefix": "tstream",
    "body": [
      "<%= turbo_stream_from \"${1:channel_name}\" %>"
    ],
    "description": "Turbo Stream subscription"
  },

  "Stimulus Controller": {
    "prefix": "stimctrl",
    "body": [
      "import { Controller } from \"@hotwired/stimulus\"",
      "",
      "export default class extends Controller {",
      "  static targets = [\"${1:target}\"]",
      "  static values = { ${2:name}: ${3:String} }",
      "",
      "  connect() {",
      "    ${0}",
      "  }",
      "}"
    ],
    "description": "Stimulus Controller base"
  },

  "ERB Tag": {
    "prefix": "erbt",
    "body": "<%= ${1} %>",
    "description": "ERB output tag"
  },

  "ERB Block": {
    "prefix": "erbb",
    "body": "<% ${1} %>",
    "description": "ERB code tag"
  }
}
```

---

## 7. Terminais recomendados (abrir no início do trabalho)

Abra 4 terminais integrados no VSCode (`Ctrl+Shift+`` ` para cada novo):

| Terminal | Comando | Para que serve |
|----------|---------|---------------|
| **Rails** | `rails server` | Servidor web principal |
| **Tailwind** | `rails tailwindcss:watch` | Compilar CSS em tempo real |
| **Sidekiq** | `bundle exec sidekiq` | Jobs assíncronos (expiração de Pix) |
| **Git / Comandos** | *(livre)* | Migrations, seeds, console |

> Dica: renomeie cada terminal clicando com botão direito no nome → "Rename".

---

## 8. Extensão REST Client — testar webhook do MercadoPago

Criar arquivo `requests.http` na raiz do projeto para testar endpoints:

```http
### Testar webhook MercadoPago (simular pagamento confirmado)
POST http://localhost:3000/webhooks/mercadopago
Content-Type: application/json

{
  "type": "payment",
  "action": "payment.updated",
  "data": {
    "id": "123456789"
  }
}

###

### Ver lista de slots disponíveis
GET http://localhost:3000/?date=2026-05-15
Accept: text/html

###

### Criar booking group (autenticado)
POST http://localhost:3000/booking_groups
Content-Type: application/json
Cookie: _videira_session=SEU_TOKEN_AQUI

{
  "availability_ids": ["uuid1", "uuid2"]
}
```

---

## 9. Estrutura de pastas do projeto (para referência no VSCode)

```
videira_dental/
├── app/
│   ├── assets/stylesheets/
│   │   └── application.css          ← CSS variables + fonte Prompt
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── home_controller.rb
│   │   ├── booking_groups_controller.rb
│   │   ├── bookings_controller.rb
│   │   ├── payments_controller.rb
│   │   ├── users_controller.rb
│   │   ├── webhooks_controller.rb
│   │   └── admin/
│   │       ├── availabilities_controller.rb
│   │       ├── bookings_controller.rb
│   │       ├── discount_rules_controller.rb
│   │       └── users_controller.rb
│   ├── javascript/controllers/
│   │   ├── countdown_controller.js
│   │   ├── clipboard_controller.js
│   │   ├── flash_controller.js
│   │   ├── modal_controller.js
│   │   ├── phone_mask_controller.js
│   │   ├── week_selector_controller.js
│   │   └── cart_controller.js
│   ├── jobs/
│   │   └── expire_payments_job.rb
│   ├── models/
│   │   ├── clinic.rb
│   │   ├── user.rb
│   │   ├── room.rb
│   │   ├── availability.rb
│   │   ├── discount_rule.rb
│   │   ├── booking_group.rb
│   │   ├── booking.rb
│   │   └── payment.rb
│   ├── policies/
│   │   ├── application_policy.rb
│   │   ├── availability_policy.rb
│   │   ├── booking_group_policy.rb
│   │   ├── booking_policy.rb
│   │   ├── discount_rule_policy.rb
│   │   └── admin/
│   │       └── user_policy.rb
│   ├── services/
│   │   ├── discount_calculator.rb
│   │   └── mercado_pago_service.rb
│   └── views/
│       ├── layouts/
│       │   ├── application.html.erb
│       │   └── admin.html.erb
│       ├── shared/
│       │   ├── _avatar.html.erb
│       │   ├── _back_button.html.erb
│       │   ├── _flash.html.erb
│       │   └── _logo.html.erb
│       ├── home/
│       │   └── index.html.erb
│       ├── booking_groups/
│       │   └── new.html.erb
│       ├── payments/
│       │   ├── show.html.erb
│       │   ├── _pending.html.erb
│       │   └── _confirmed.html.erb
│       ├── bookings/
│       │   └── index.html.erb
│       ├── users/
│       │   └── show.html.erb
│       └── admin/
│           ├── availabilities/
│           ├── bookings/
│           ├── discount_rules/
│           └── users/
├── .env                              ← NÃO versionar
├── .editorconfig
├── .rubocop.yml
├── requests.http                     ← Testes REST Client
├── CONTEXT.md                        ← Contexto para IA
├── DESIGN_SYSTEM.md                  ← Tokens de design
├── ROADMAP.md                        ← Lista de tarefas
└── docker-compose.yml                ← LibreChat + Ollama
```

---

## 10. Checklist rápido "antes de codar"

Toda vez que abrir o projeto, confirmar:

- [ ] PostgreSQL rodando: `pg_isready`
- [ ] Redis rodando: `redis-cli ping` → PONG
- [ ] `.env` preenchido (MP sandbox + Google OAuth)
- [ ] `rails server` no terminal 1
- [ ] `rails tailwindcss:watch` no terminal 2
- [ ] `bundle exec sidekiq` no terminal 3

---

*Configuração válida para Ruby LSP + Rails 7.2 + Tailwind 3+ — Abril 2026*
