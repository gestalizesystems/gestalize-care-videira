# InfinitePay — Guia de Integração

> Documento de referência para substituição do MercadoPago pelo InfinitePay no Videira Dental.
> Última atualização: 2026-06-09

---

## Links essenciais

| O que | Link |
|---|---|
| Documentação Checkout API | https://www.infinitepay.io/checkout-documentacao |
| Painel do desenvolvedor / conta | https://app.infinitepay.io |
| Site principal | https://www.infinitepay.io |

---

## Como o InfinitePay funciona (diferença crítica vs. MercadoPago)

O MercadoPago gerava um **QR Code Pix inline** — o dentista ficava na tela do app e escaneava direto.

O InfinitePay funciona como **Hosted Checkout**: o sistema cria um link de pagamento e **redireciona o dentista** para uma página hospedada pelo InfinitePay. Lá ele escolhe Pix ou cartão, paga, e é redirecionado de volta.

```
Videira Dental                    InfinitePay
     │                                 │
     │── POST /links ─────────────────>│
     │<─ { checkout_url } ─────────────│
     │                                 │
     │── redireciona dentista ─────────>│
     │                    (dentista paga)│
     │<─ redirect_url + query params ───│
     │<─ webhook POST ──────────────────│
```

**Impacto na UX:** não haverá mais QR Code na tela, countdown de 30 minutos, nem cópia de código — o dentista é levado à página do InfinitePay.

---

## Credenciais necessárias

| Variável de ambiente | O que é | Onde obter |
|---|---|---|
| `INFINITEPAY_HANDLE` | Seu InfiniteTag (username sem "$") | Painel InfinitePay → Perfil |
| `INFINITEPAY_WEBHOOK_URL` | URL pública que recebe confirmações | Definido por você (`/webhooks/infinitepay`) |

> **Atenção:** A documentação pública não menciona API key nem Bearer token — a identificação é feita pelo `handle`. Confirme no painel se há algum token adicional para produção.

> **Sandbox:** Não há ambiente de sandbox documentado. Teste em produção com valores baixos (R$ 0,01) ou confirme com o suporte se existe ambiente de homologação.

---

## API — Referência

### Base URL

```
https://api.checkout.infinitepay.io
```

---

### `POST /links` — Criar cobrança

**Cria um link de checkout.** Retorna uma URL para redirecionar o dentista.

#### Request

```json
{
  "handle": "videira-dental",
  "items": [
    {
      "quantity": 1,
      "price": 17000,
      "description": "Aluguel de Sala — Turno Manhã 09/06"
    }
  ],
  "order_nsu": "UUID-do-booking-group",
  "redirect_url": "https://seudominio.com.br/pagamento/UUID/retorno",
  "webhook_url": "https://seudominio.com.br/webhooks/infinitepay",
  "customer": {
    "name": "Dra. Ana Silva",
    "email": "ana@email.com",
    "phone_number": "+5511999887766"
  }
}
```

| Campo | Tipo | Obrigatório | Observação |
|---|---|---|---|
| `handle` | string | ✅ | InfiniteTag sem "$" |
| `items` | array | ✅ | Mínimo 1 item |
| `items[].quantity` | integer | ✅ | Quantidade |
| `items[].price` | integer | ✅ | Valor em centavos (R$170,00 = 17000) |
| `items[].description` | string | ✅ | Descrição da cobrança |
| `order_nsu` | string | ⭐ Recomendado | ID do `BookingGroup` — usado para rastrear no webhook |
| `redirect_url` | string | ⭐ Recomendado | URL de retorno após pagamento |
| `webhook_url` | string | ⭐ Recomendado | URL que recebe confirmação de pagamento |
| `customer.name` | string | ❌ | Nome do pagador |
| `customer.email` | string | ❌ | E-mail do pagador |
| `customer.phone_number` | string | ❌ | Telefone com DDI (+55...) |

#### Response (esperada)

A documentação não detalha o body de resposta do `POST /links`. Espera-se uma URL de checkout:

```json
{
  "checkout_url": "https://checkout.infinitepay.io/abc123"
}
```

> Confirme o campo exato da URL no painel ou com o suporte InfinitePay.

---

### `POST /payment_check` — Consultar status

Fallback manual para verificar se um pagamento foi aprovado (útil se o webhook não chegar).

#### Request

```json
{
  "handle": "videira-dental",
  "order_nsu": "UUID-do-booking-group",
  "transaction_nsu": "UUID-da-transacao",
  "slug": "codigo-da-fatura"
}
```

#### Response

```json
{
  "success": true,
  "paid": true,
  "amount": 17000,
  "paid_amount": 17000,
  "installments": 1,
  "capture_method": "pix"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| `success` | boolean | Requisição processada com sucesso |
| `paid` | boolean | Pagamento aprovado |
| `amount` | integer | Valor cobrado em centavos |
| `paid_amount` | integer | Valor efetivamente pago |
| `capture_method` | string | `"pix"` ou `"credit_card"` |

---

## Webhook — Confirmação de pagamento

O InfinitePay envia `POST` para o `webhook_url` que você passou ao criar o link.

### Payload recebido

```json
{
  "invoice_slug": "abc123",
  "amount": 17000,
  "paid_amount": 17000,
  "installments": 1,
  "capture_method": "pix",
  "transaction_nsu": "UUID-da-transacao",
  "order_nsu": "UUID-do-booking-group",
  "receipt_url": "https://comprovante.infinitepay.io/abc123",
  "items": [
    {
      "quantity": 1,
      "price": 17000,
      "description": "Aluguel de Sala — Turno Manhã"
    }
  ]
}
```

| Campo | Uso no sistema |
|---|---|
| `order_nsu` | Mapeia para `BookingGroup.id` — use para confirmar o grupo correto |
| `paid` / `paid_amount` | Confirma que o pagamento foi aprovado |
| `capture_method` | Registra se foi Pix ou cartão |
| `transaction_nsu` | ID da transação InfinitePay — salvar como `gateway_id` |
| `invoice_slug` | Código da fatura — salvar como referência |

### Regras de resposta

- Responda `200 OK` em menos de 1 segundo
- Se retornar `400`, o InfinitePay reenvia automaticamente
- **Não há menção de assinatura HMAC** — a validação é pelo `order_nsu` (confirme com o suporte)

---

## Expiração do Pix e pagamento tardio

A API de `links` do InfinitePay **não aceita campo de expiração** — o link/Pix fica válido por
~2 dias do lado deles, e isso **não é configurável** pelo app. A expiração efetiva é controlada
pelo próprio sistema:

- `PAYMENT_EXPIRY_MINUTES` (default **30**) define o `Payment#expires_at` na criação do checkout.
- `ExpirePaymentsJob` (Sidekiq Cron, **a cada 1 min**) marca pagamentos vencidos como `expired`
  e libera a vaga (`BookingGroup#expire!`).

**Pagamento que chega depois da expiração** (`PaymentConfirmer#credit_late_payment`):

1. A reserva já está `expired` (vaga liberada, possivelmente reservada por outra pessoa).
2. O sistema **não confirma** essa reserva (evita conflito de vaga).
3. Em vez de ignorar, **converte o valor pago em crédito** na conta do dentista
   (`CreditIssuer`) e envia o e-mail "Crédito disponível".
4. É **idempotente** — webhook repetido não credita duas vezes.

> Resultado: ninguém perde dinheiro e não há double-booking, mesmo o link do InfinitePay
> permanecendo válido por mais tempo do lado deles.

---

## Redirect de retorno

Após o pagamento, o InfinitePay redireciona o dentista para o `redirect_url` com query params:

```
https://seudominio.com.br/pagamento/UUID/retorno
  ?receipt_url=https://...
  &order_nsu=UUID-do-booking-group
  &slug=abc123
  &capture_method=pix
  &transaction_nsu=UUID-da-transacao
```

Use `order_nsu` para identificar qual `BookingGroup` confirmar.

---

## Variáveis de ambiente necessárias

```bash
# .env (local) e variáveis no serviço da Railway (produção)
INFINITEPAY_HANDLE=seu-handle-sem-cifrao
```

Compare com as que serão **removidas** (MercadoPago):
```bash
# Remover:
MERCADOPAGO_ACCESS_TOKEN=
MERCADOPAGO_PUBLIC_KEY=
MERCADOPAGO_WEBHOOK_SECRET=
```

---

## Mudanças no sistema

### O que muda na UX
- ❌ Não há mais QR Code inline na tela de pagamento
- ❌ Não há countdown de 30 minutos
- ❌ Não há botão "copiar código Pix"
- ✅ Dentista é redirecionado para o checkout do InfinitePay
- ✅ Ao voltar, a tela de confirmação é exibida

### Arquivos que precisam ser alterados

| Arquivo | O que muda |
|---|---|
| `app/services/mercado_pago/` | Substituir por `app/services/infinite_pay/` |
| `app/services/booking_group_creator.rb` | Trocar `MercadoPago::PixCreator` por `InfinitePay::CheckoutCreator` |
| `app/services/payment_confirmer.rb` | Adaptar para payload InfinitePay |
| `app/controllers/payments/webhooks_controller.rb` | Trocar validação HMAC pelo `order_nsu` |
| `app/controllers/payments/payments_controller.rb` | Adaptar tela de retorno |
| `app/views/payments/payments/` | Remover partials `_pending` (QR code), simplificar `_paid` |
| `app/models/payment.rb` | Campo `gateway` muda de `"mercadopago"` para `"infinitepay"` |
| Variáveis no serviço da Railway (e `.env.example`) | Trocar vars MP por `INFINITEPAY_HANDLE` |
| `README.md` | Atualizar seção de configuração |
| `.env.example` | Trocar vars MP por InfinitePay |

### Novo fluxo de pagamento

```
1. BookingGroupCreator → InfinitePay::CheckoutCreator.call(group)
2. Salva Payment com gateway: "infinitepay", gateway_id: transaction_nsu
3. Redireciona dentista para checkout_url
4. Dentista paga no InfinitePay
5. InfinitePay → POST /webhooks/infinitepay (order_nsu = booking_group.id)
6. PaymentConfirmer confirma + Turbo Stream atualiza tela
7. Dentista retorna via redirect_url → tela de confirmação
```

---

## Dúvidas para confirmar com o suporte InfinitePay

- [ ] Existe ambiente de sandbox/homologação?
- [ ] Qual o campo exato da URL no response do `POST /links`?
- [ ] Há autenticação adicional além do `handle` (Bearer token, API key)?
- [ ] O webhook tem assinatura para validação (HMAC ou similar)?
- [ ] É possível gerar QR Code Pix inline (sem redirect) via outra API?
