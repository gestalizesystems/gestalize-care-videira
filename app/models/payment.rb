class Payment < ApplicationRecord
  include MoneyConvertible
  money_field :amount

  has_paper_trail

  belongs_to :clinic
  belongs_to :booking_group

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :gateway,      presence: true
  validates :checkout_url, presence: true, if: -> { gateway == "infinitepay" && pending? }

  enum :status, {
    pending:   "pending",
    paid:      "paid",
    failed:    "failed",
    cancelled: "cancelled",
    expired:   "expired"
  }

  scope :pending,  -> { where(status: "pending") }
  scope :expired_unpaid, -> { pending.where("expires_at < ?", Time.current) }

  def expired?
    expires_at.present? && expires_at < Time.current
  end

end
