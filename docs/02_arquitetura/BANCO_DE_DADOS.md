# Videira Dental Clinic — BANCO_DE_DADOS.md

> Schema PostgreSQL **real**, espelhado de `db/schema.rb` (versão 2026_06_11_120000).
> Última atualização: 2026-06-11 (auditoria código × docs)

---

## 1. Convenções

- **PK:** UUID (`gen_random_uuid()` via pgcrypto) em todas as tabelas de domínio.
- **Dinheiro:** sempre `*_cents` (integer) com check constraint de positividade. Conversão para reais via concern `MoneyConvertible`.
- **Status:** `string` com **check constraint** no Postgres + `enum` string no model (legível em queries SQL diretas; ordem não importa).
- **FKs:** constraint real no banco (`add_foreign_key`) em todas as relações.
- **Auditoria:** tabela `versions` (PaperTrail) com `object_changes`.

> Divergência histórica: o plano original (2026-05) previa enums integer, money decimal e tabela `rooms`. A implementação real usa enums string, centavos e **não tem `rooms`** — o conceito virou `services` (tipo de turno/atendimento) + `availabilities` ligadas direto à clínica.

---

## 2. Tabelas de domínio

### clinics — tenant root
| Coluna | Tipo | Regras |
|---|---|---|
| name, cnpj, phone, email | string | `null: false`; `cnpj` unique |
| logo_url | string | opcional (logo também via Active Storage) |

### users — owner e dentistas (Devise)
| Coluna | Tipo | Regras |
|---|---|---|
| clinic_id | uuid | FK, **nullable** (associada no cadastro) |
| name | string | `null: false` |
| role | string | check: `owner` \| `dentist` (default `dentist`) |
| email / encrypted_password / reset_* / remember_* | — | Devise |
| provider, uid | string | Google OAuth; unique parcial `(provider, uid)` |
| phone, birth_date, cpf, cro, specialty | — | cpf unique parcial |

### services — tipos de turno/atendimento
| Coluna | Tipo | Regras |
|---|---|---|
| clinic_id | uuid | FK `null: false` |
| name | string | `null: false` |
| duration_minutes | integer | check `> 0` |
| price_cents | integer | check `>= 0` |
| active | boolean | default true |

### availabilities — turnos (slots) da agenda
| Coluna | Tipo | Regras |
|---|---|---|
| clinic_id | uuid | FK `null: false` |
| service_id | uuid | FK, opcional |
| dentist_id | uuid | FK → users, opcional |
| date / starts_at / ends_at | date / time | `null: false` |
| price_cents | integer | default 0 |
| status | string | check: `available` \| `booked` \| `cancelled` \| `blocked` |

Índice único `idx_availabilities_no_double_booking` em `(dentist_id, date, starts_at)`.

### discount_rules — desconto por volume
| Coluna | Tipo | Regras |
|---|---|---|
| clinic_id | uuid | FK `null: false` |
| min_slots | integer | check `> 0` |
| discount_percent | integer | check `1..100` |
| active | boolean | unique parcial `(clinic_id, min_slots)` where active |

### booking_groups — N reservas sob 1 pagamento
| Coluna | Tipo | Regras |
|---|---|---|
| clinic_id / dentist_id | uuid | FK `null: false` |
| discount_rule_id | uuid | FK, opcional |
| subtotal_cents / total_cents | integer | `null: false`; `total_cents > 0` |
| discount_cents | integer | default 0, check `>= 0` |
| status | string | check: `pending` \| `confirmed` \| `cancelled` \| `expired` |

### bookings — reserva individual de um slot
| Coluna | Tipo | Regras |
|---|---|---|
| clinic_id / booking_group_id / availability_id / dentist_id | uuid | FK `null: false` |
| price_cents | integer | check `>= 0` |
| status | string | check: `pending` \| `confirmed` \| `cancelled` |

**Defesa canônica contra double-booking:** índice único parcial `idx_bookings_availability_unique_active` em `availability_id` where `status <> 'cancelled'`.

### payments — pagamentos do grupo (InfinitePay)
| Coluna | Tipo | Regras |
|---|---|---|
| clinic_id / booking_group_id | uuid | FK `null: false`; **1—N** desde 2026-06-11 (pagamento principal + pagamentos de diferença na troca de turno) |
| amount_cents | integer | check `> 0` |
| status | string | check: `pending` \| `paid` \| `failed` \| `cancelled` \| `expired` |
| gateway | string | default `infinitepay` |
| gateway_id | string | `transaction_nsu` do InfinitePay; unique parcial |
| checkout_url | string | link do checkout hospedado |
| expires_at / paid_at | datetime | janela `PAYMENT_EXPIRY_MINUTES` |

> Não existem mais colunas Pix inline (`pix_code`, `pix_qr_url`) — removidas na migração MercadoPago → InfinitePay (`ReplaceMercadopagoWithInfinitepay`).

### credits — crédito em conta do dentista
| Coluna | Tipo | Regras |
|---|---|---|
| user_id / clinic_id | uuid | FK `null: false` |
| source_booking_group_id | uuid | FK, opcional (origem: cancelamento) |
| used_on_booking_group_id | uuid | FK, opcional (consumo no checkout) |
| amount_cents | integer | check `> 0` |
| reason | string | ex.: "Recarga via Pix" |
| used_at | datetime | null = disponível |

Índice composto `(user_id, clinic_id, used_at)` para o cálculo de saldo (`Credit.balance_for`). Sem validade (`expires_at`) por decisão de produto.

### credit_purchases — recarga de crédito via Pix
| Coluna | Tipo | Regras |
|---|---|---|
| user_id / clinic_id | uuid | FK `null: false` |
| credit_id | uuid | FK, opcional — preenchido na confirmação |
| amount_cents | integer | check `> 0` |
| status | string | `pending` \| `paid` \| `expired` \| `cancelled` (enum no model; **sem** check constraint — só índice em status) |
| gateway / gateway_id / checkout_url / expires_at / paid_at | — | mesmos campos de payments |

### versions — PaperTrail
`item_type/item_id` (string — compatível com UUID), `whodunnit`, `event`, `object`, `object_changes`.

### active_storage_*
Tabelas padrão do Active Storage (avatares de usuário e logo da clínica). PKs bigint (default Rails).

---

## 3. Relacionamentos

```
Clinic 1—N User, Service, Availability, DiscountRule, BookingGroup, Booking,
           Payment, Credit, CreditPurchase

User (dentist) 1—N BookingGroup, Booking, Credit, CreditPurchase
Service 1—N Availability (opcional)
Availability 1—1 Booking (ativo; índice parcial)
BookingGroup 1—N Booking
BookingGroup 1—N Payment (principal + diferenças de troca de turno)
BookingGroup 1—N Credit (como origem ou consumo)
CreditPurchase 1—1 Credit (após confirmação)
```

---

## 4. Decisões de schema (o porquê)

| Decisão | Motivo |
|---|---|
| UUID como PK | IDs vazam em URLs e `order_nsu` do gateway — não enumeráveis |
| Centavos (integer) | Evita erro de arredondamento de float/decimal em soma de carrinho e desconto |
| Enum string + check constraint | Banco legível em suporte/BI; constraint impede estado inválido mesmo fora do Rails |
| Índice único parcial em bookings | Garante no banco que um slot só tem 1 reserva ativa, independente de bug na aplicação |
| `payments.booking_group_id` 1—N (era unique até 2026-06-11) | Troca de turno pelo admin pode gerar pagamento de diferença adicional ao pagamento principal |
| Crédito sem `expires_at` | Decisão de produto (registrada em ATIVIDADES.md) |
| `users.clinic_id` nullable | Cadastro via OAuth pode preceder associação à clínica |

---

## 5. Pendências de schema (roadmap)

- `credit_purchases.status` sem check constraint (inconsistente com as demais tabelas).
- `bookings` não tem `cancel_reason` / `cancelled_at` (o motivo do cancelamento hoje não é persistido na reserva).
- Integração Google Agenda exigirá `users.google_refresh_token` (+ `bookings.google_calendar_event_id`) — ver README.

---

*Fonte da verdade do schema é sempre `db/schema.rb`. Este documento é o mapa comentado.*
