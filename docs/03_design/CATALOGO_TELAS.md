# Catálogo de telas — Videira Dental

> Listagem das telas existentes para servir de **referência ao criar uma tela nova**.
> Quando for construir algo, encontre aqui a tela mais parecida e use como ponto de partida.
>
> **Tipos de padrão** (ver detalhes em [`TEMPLATE_TELA_E_MODAL.md`](TEMPLATE_TELA_E_MODAL.md)):
> - **A** = Formulário (com card único envolvendo campos)
> - **B** = Listagem (cards verticais clicáveis)
> - **C** = Detalhe / show (header + lista de itens em cards individuais + resumo)
> - **D** = Dashboard / hub (grid de cards de navegação)
> - **E** = Página estática (texto + cards de info)

---

## Públicas / não-autenticadas

| Tela | View | Tipo | Observações |
|---|---|---|---|
| Home (escolher horários) | `pages/home.html.erb` | **B** | Calendário + lista de `_slot_card`. Tem date filter, week strip e turbo frame de carrinho. |
| Sobre | `pages/about.html.erb` | **E** | Textos institucionais em cards. |
| Contato | `pages/contact.html.erb` | **E** | Cards com informações de contato. |

## Auth (Devise customizado)

| Tela | View | Tipo | Observações |
|---|---|---|---|
| Login | `auth/sessions/new.html.erb` | **A** | Tabs Entrar/Criar conta. Form em card principal. |
| Cadastro | `auth/registrations/new.html.erb` | **A** | Tabs Entrar/Criar conta. Form mais longo. |
| Recuperar senha (request) | `devise/passwords/new.html.erb` | **A** | Form simples + `.btn-cta`. |
| Recuperar senha (reset) | `devise/passwords/edit.html.erb` | **A** | Form simples + `.btn-cta`. |
| Reenviar confirmação | `devise/confirmations/new.html.erb` | **A** | Form simples + `.btn-cta`. |
| Desbloquear conta | `devise/unlocks/new.html.erb` | **A** | Form simples + `.btn-cta`. |

## Fluxo do dentista (autenticado)

| Tela | View | Tipo | Observações |
|---|---|---|---|
| Carrinho | `scheduling/carts/show.html.erb` | **C** | Lista de itens + total + CTA "Confirmar e gerar Pix". |
| Confirmar reserva | `scheduling/bookings/new.html.erb` | **C** | Resumo do pedido com desconto e crédito aplicado. |
| Minhas reservas | `scheduling/bookings/index.html.erb` | **B** | Cards `.card-link` com badge de status via `booking_group_status_badge`. Empty state com `.btn-cta`. |
| Detalhe de reserva | `scheduling/bookings/show.html.erb` | **C** | Header com status badge, lista de bookings em cards individuais, card de total, CTA para pagamento. |
| Pagamento (wrapper) | `payments/payments/show.html.erb` | **C** | Resumo + turbo frame com partial conforme status. |
| Pagamento pendente | `payments/payments/_pending.html.erb` | — | Partial com QR Pix, copia-cola e countdown. |
| Pagamento pago | `payments/payments/_paid.html.erb` | — | Partial de sucesso (verde). |
| Pagamento expirado | `payments/payments/_expired.html.erb` | — | Partial de fim de prazo. |
| Meu perfil | `users/profiles/show.html.erb` | **C** | Card grande com avatar e dados + card de créditos + card de últimas reservas. |
| Editar perfil | `users/profiles/edit.html.erb` | **A** | Form com labels acima de cada input. |
| Carteira | `users/wallets/show.html.erb` | **C** | Saldo de créditos + form de recarga via Pix (POST `/recargas`). |

## Admin

| Tela | View | Tipo | Observações |
|---|---|---|---|
| Dashboard | `admin/dashboard/index.html.erb` | **D** | KPIs em cards, gráfico SVG inline, grid de `.card-link` para navegação. |
| Reservas — index | `admin/bookings/index.html.erb` | **B** | Filtros por status + data, cards `.card-link` com badge. |
| Reservas — show | `admin/bookings/show.html.erb` | **C** | Card principal + lista de bookings + card de total + histórico. |
| Pagamentos — index | `admin/payments/index.html.erb` | **B** | Filtro por status, `.card-link` com `payment_status_badge`. |
| Pagamentos — show | `admin/payments/show.html.erb` | **C** | Header com badge, lista de bookings em cards, histórico. |
| Usuários — index | `admin/users/index.html.erb` | **B** | Busca + cards com avatar + botões `.btn-xs-outline`. |
| Usuários — show | `admin/users/show.html.erb` | **C** | Card de perfil + card de últimas reservas + histórico de versões. |
| Usuários — editar | `admin/users/edit.html.erb` | **A** | Form padrão. Reusa partial `_edit_form`. |
| Disponibilidades — index | `admin/availabilities/index.html.erb` | **B** | Calendário + lista de turnos + modais de adicionar/editar/excluir. |
| Disponibilidades — novo/editar | `admin/availabilities/new.html.erb` + `edit.html.erb` | **A** | Form em card. |
| Descontos — index | `admin/discount_rules/index.html.erb` | **B** | Lista de regras + modais. |
| Descontos — novo/editar | `admin/discount_rules/new.html.erb` + `edit.html.erb` | **A** | Form em card. |
| Serviços — index | `admin/services/index.html.erb` | **B** | Lista de serviços. |
| Serviços — novo/editar | `admin/services/new.html.erb` + `edit.html.erb` | **A** | Form em card. |
| Créditos | `admin/credits/index.html.erb` | **B** | Filtros por status + cards. |
| Clínica | `admin/clinics/show.html.erb` | **C** | Card de dados + card de estatísticas + modal de editar. |

---

## Como usar este catálogo

1. **Identifique o tipo** da tela que vai criar (A/B/C/D/E).
2. **Procure uma tela equivalente** acima — abrir a view para usar como base.
3. **Verifique no [`TEMPLATE_TELA_E_MODAL.md`](TEMPLATE_TELA_E_MODAL.md)** o esqueleto da Variação correspondente para validar a estrutura.
4. **Use helpers e classes** documentados em [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md).
5. **Após criar a tela nova**, adicione uma linha aqui neste catálogo.

---

*Atualizar este catálogo sempre que uma tela for adicionada/removida/renomeada.*
