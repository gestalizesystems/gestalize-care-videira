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

  # Ao confirmar, cria os eventos na Google Agenda da owner (assíncrono).
  after_update_commit :sync_google_calendar_on_confirm

  def expire!
    return unless pending?
    release_bookings!(final_status: "expired")
  end

  def cancel!
    return if cancelled?
    release_bookings!(final_status: "cancelled")
  end

  private

  def sync_google_calendar_on_confirm
    GoogleCalendarSyncJob.perform_later("create", id) if saved_change_to_status? && confirmed?
  end

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
