# Compra de insumos (Videira Shop) vinculada a uma reserva confirmada já
# existente. Cria um pagamento Pix avulso; os insumos só são anexados à reserva
# quando o pagamento é confirmado (guardados no próprio pagamento até lá).
class ExtrasPurchaseCreator < ApplicationService
  def initialize(booking_group:, extras:)
    @group  = booking_group
    @extras = extras # [[Extra, qty], ...]
    @total  = @extras.sum { |extra, qty| extra.price_cents * qty }
  end

  def call
    return failure("Selecione ao menos um insumo.") if @extras.empty? || @total <= 0
    return failure("Reserva inválida.")              unless @group

    nsu = SecureRandom.uuid
    checkout = InfinitePay::DifferenceCheckoutCreator.call(
      booking_group: @group, amount_cents: @total, order_nsu: nsu,
      description: "Insumos — Videira Clinic"
    )
    return failure(checkout.error) unless checkout.success?

    payment = @group.payments.create!(
      id:           nsu,
      clinic:       @group.clinic,
      gateway:      "infinitepay",
      status:       "pending",
      amount_cents: @total,
      extras:       serialized_extras,
      checkout_url: checkout.value[:checkout_url],
      expires_at:   checkout.value[:expires_at]
    )

    success(payment)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def serialized_extras
    @extras.map do |extra, qty|
      { "id" => extra.id, "name" => extra.name, "price_cents" => extra.price_cents, "quantity" => qty }
    end
  end
end
