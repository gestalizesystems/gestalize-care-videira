class BookingGroup < ApplicationRecord
  has_paper_trail

  belongs_to :clinic
  belongs_to :dentist, class_name: "User", foreign_key: :patient_id
  belongs_to :discount_rule, optional: true
  has_many   :bookings, dependent: :destroy
  has_one    :payment,  dependent: :destroy

  validates :subtotal_cents, :total_cents, presence: true,
    numericality: { greater_than: 0 }
  validates :discount_cents, numericality: { greater_than_or_equal_to: 0 }

  enum :status, {
    pending:   "pending",
    confirmed: "confirmed",
    cancelled: "cancelled",
    expired:   "expired"
  }

  def expire!
    return unless pending?
    transaction do
      update!(status: "expired")
      bookings.each { |b| b.update!(status: "cancelled") }
      bookings.each { |b| b.availability.update!(status: "available") }
    end
  end

  def cancel!
    return if cancelled?
    transaction do
      update!(status: "cancelled")
      bookings.each { |b| b.update!(status: "cancelled") }
      bookings.each { |b| b.availability.update!(status: "available") }
    end
  end
end
