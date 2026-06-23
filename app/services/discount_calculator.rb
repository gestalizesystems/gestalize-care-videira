class DiscountCalculator < ApplicationService
  def initialize(availability_ids:, clinic:, dentist: nil)
    @availability_ids = Array(availability_ids)
    @clinic = clinic
    @dentist = dentist
  end

  def call
    return failure("Horário inválido ou não encontrado.") unless @clinic

    availabilities = Availability.where(id: @availability_ids, clinic: @clinic, status: "available")
    subtotal_cents  = availabilities.sum(&:price_cents)
    # "Hora Avulsa" e "Diária" não contam para desconto: nem no mínimo, nem no valor.
    discountable    = availabilities.reject { |a| a.avulsa? || a.diaria? }

    personal = @dentist&.discount_per_slot_cents.to_i
    if personal.positive?
      # Desconto pessoal do cliente: valor fixo por turno elegível (sobrepõe a regra por volume).
      rule           = nil
      discount_cents = personal * discountable.size
    else
      rule           = DiscountRule.best_for(@clinic.id, discountable.size)
      discount_cents = rule ? rule.discount_cents * discountable.size : 0
    end
    discount_cents = [discount_cents, subtotal_cents].min
    total_cents    = subtotal_cents - discount_cents

    success({
      availabilities:  availabilities,
      subtotal_cents:  subtotal_cents,
      discount_cents:  discount_cents,
      total_cents:     total_cents,
      discount_rule:   rule
    })
  end
end
