class Availability < ApplicationRecord
  has_paper_trail skip: [:status]

  belongs_to :clinic
  belongs_to :service, optional: true
  belongs_to :dentist, class_name: "User", optional: true
  has_one    :booking

  validates :date,        presence: true
  validates :starts_at,   presence: true
  validates :ends_at,     presence: true
  validates :price_cents, presence: true,
                          numericality: { greater_than_or_equal_to: 0 }

  validate :ends_after_starts
  validate :no_overlapping_slots

  enum :status, {
    available:  "available",
    booked:     "booked",
    cancelled:  "cancelled",
    blocked:    "blocked"
  }

  scope :available, -> { where(status: "available") }
  scope :future,    -> { where("date >= ?", Date.current) }
  scope :for_date,  ->(date) { where(date: date) }

  # Derives a human label from the time slot
  def label
    return "Aluguel de Sala" unless starts_at
    case starts_at.hour
    when  0..5  then "Turno Madrugada"
    when  6..11 then "Turno Manhã"
    when 12..17 then "Turno Tarde"
    when 18..23 then "Turno Noite"
    end
  end

  def price
    price_cents / 100.0
  end

  def cancellable?
    return false if cancelled?
    slot_start = Time.zone.local(date.year, date.month, date.day,
                                 starts_at.hour, starts_at.min)
    lead_hours = ENV.fetch("CANCELLATION_LEAD_HOURS", 48).to_i
    slot_start > lead_hours.hours.from_now
  end

  private

  def ends_after_starts
    return unless starts_at && ends_at
    errors.add(:ends_at, "deve ser após o horário de início") if ends_at <= starts_at
  end

  def no_overlapping_slots
    return unless date && starts_at && ends_at && clinic_id

    overlap = clinic.availabilities
      .where(date: date)
      .where.not(id: id)
      .where.not(status: %w[cancelled])
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)

    errors.add(:base, "Já existe um turno neste intervalo de horário") if overlap.exists?
  end
end
