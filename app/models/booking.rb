class Booking < ApplicationRecord
  include MoneyConvertible
  money_field :price

  has_paper_trail

  belongs_to :clinic
  belongs_to :booking_group
  belongs_to :availability
  belongs_to :dentist, class_name: "User"

  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  enum :status, {
    pending:   "pending",
    confirmed: "confirmed",
    cancelled: "cancelled"
  }

  # Ao cancelar um turno que já tinha evento na agenda, remove o evento.
  after_update_commit :remove_google_calendar_event

  private

  def remove_google_calendar_event
    return unless saved_change_to_status? && cancelled? && google_event_id.present?

    GoogleCalendarSyncJob.perform_later("remove", id)
  end
end
