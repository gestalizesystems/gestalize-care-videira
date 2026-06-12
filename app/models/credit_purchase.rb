class CreditPurchase < ApplicationRecord
  include MoneyConvertible
  money_field :amount

  has_paper_trail

  belongs_to :user
  belongs_to :clinic
  belongs_to :credit, optional: true

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :gateway, presence: true

  enum :status, {
    pending:   "pending",
    paid:      "paid",
    expired:   "expired",
    cancelled: "cancelled"
  }

  def past_due?
    expires_at.present? && expires_at < Time.current
  end
end
