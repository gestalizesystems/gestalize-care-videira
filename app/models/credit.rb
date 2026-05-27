class Credit < ApplicationRecord
  has_paper_trail

  belongs_to :user
  belongs_to :clinic
  belongs_to :source_booking_group,  class_name: "BookingGroup", optional: true
  belongs_to :used_on_booking_group, class_name: "BookingGroup", optional: true

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }

  scope :available, -> { where(used_at: nil) }
  scope :used,      -> { where.not(used_at: nil) }

  def self.balance_for(user:, clinic:)
    available.where(user: user, clinic: clinic).sum(:amount_cents)
  end

  def available?
    used_at.nil?
  end

  def amount
    amount_cents / 100.0
  end
end
