class BookingGroup < ApplicationRecord
  has_paper_trail

  belongs_to :clinic
  belongs_to :dentist, class_name: "User"
  belongs_to :discount_rule, optional: true
  has_many   :bookings, dependent: :destroy
  has_many   :payments, dependent: :destroy
  # Pagamento principal (o mais antigo) — compatibilidade com o fluxo existente.
  has_one    :payment, -> { order(created_at: :asc) }

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
    release_bookings!(final_status: "expired")
  end

  def cancel!
    return if cancelled?
    release_bookings!(final_status: "cancelled")
  end

  private

  def release_bookings!(final_status:)
    transaction do
      update!(status: final_status)
      bookings.each do |b|
        b.update!(status: "cancelled")
        b.availability.update!(status: "available")
      end
    end
  end
end
