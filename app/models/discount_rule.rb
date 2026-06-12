class DiscountRule < ApplicationRecord
  has_paper_trail

  belongs_to :clinic
  has_many :booking_groups

  validates :min_slots,        presence: true, numericality: { greater_than: 0 }
  validates :discount_percent, presence: true, numericality: { in: 1..100 }
  validates :min_slots, uniqueness: { scope: :clinic_id, conditions: -> { where(active: true) } }

  scope :active, -> { where(active: true) }

  def self.best_for(clinic_id, slot_count)
    where(clinic_id: clinic_id, active: true)
      .where("min_slots <= ?", slot_count)
      .order(min_slots: :desc)
      .first
  end

  def deactivate!
    update!(active: false)
  end
end
