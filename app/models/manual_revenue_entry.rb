# Lançamento manual de receita feito pelo admin no dashboard — para registrar
# receita que não passou pelo fluxo normal de reserva/pagamento do sistema.
class ManualRevenueEntry < ApplicationRecord
  include MoneyConvertible
  money_field :amount

  belongs_to :clinic
  belongs_to :client,     class_name: "User"
  belongs_to :created_by, class_name: "User"

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :category, inclusion: { in: %w[turno insumo] }
  validates :month, presence: true

  scope :for_month, ->(month) { where(month: month.beginning_of_month) }
end
