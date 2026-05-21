class DiscountCalculator < ApplicationService
  def initialize(availability_ids:, clinic:)
    @availability_ids = Array(availability_ids)
    @clinic = clinic
  end

  def call
    return failure("Conta não associada a uma clínica.") unless @clinic

    availabilities = Availability.where(id: @availability_ids, clinic: @clinic, status: "available")
    subtotal_cents  = availabilities.sum(&:price_cents)
    rule            = DiscountRule.best_for(@clinic.id, availabilities.size)
    discount_cents  = rule ? (subtotal_cents * rule.discount_percent / 100.0).floor : 0
    total_cents     = subtotal_cents - discount_cents

    success({
      availabilities:  availabilities,
      subtotal_cents:  subtotal_cents,
      discount_cents:  discount_cents,
      total_cents:     total_cents,
      discount_rule:   rule,
      discount_percent: rule&.discount_percent || 0
    })
  end
end
