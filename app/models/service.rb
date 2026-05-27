class Service < ApplicationRecord
  belongs_to :clinic
  has_many :availabilities, dependent: :restrict_with_error

  validates :name,             presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :price_cents,      presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }

  def price
    price_cents / 100.0
  end
end
