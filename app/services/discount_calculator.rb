class DiscountCalculator < ApplicationService
  def initialize(availability_ids:, clinic:)
    @availability_ids = Array(availability_ids)
    @clinic = clinic
  end

  def call
    return failure("Horário inválido ou não encontrado.") unless @clinic

    availabilities = Availability.where(id: @availability_ids, clinic: @clinic, status: "available")
    subtotal_cents  = availabilities.sum(&:price_cents)
    rule            = DiscountRule.best_for(@clinic.id, availabilities.size)
    # Desconto é por turno: valor fixo × quantidade de turnos (limitado ao subtotal).
    discount_cents  = rule ? [rule.discount_cents * availabilities.size, subtotal_cents].min : 0
    total_cents     = subtotal_cents - discount_cents

    success({
      availabilities:  availabilities,
      subtotal_cents:  subtotal_cents,
      discount_cents:  discount_cents,
      total_cents:     total_cents,
      discount_rule:   rule
    })
  end
end
