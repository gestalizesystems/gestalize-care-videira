class Availability < ApplicationRecord
  include MoneyConvertible
  money_field :price

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
  validate :not_in_the_past, on: :create

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
    return "Hora Avulsa" if avulsa?
    case starts_at.hour
    when  0..5  then "Turno Madrugada"
    when  6..11 then "Turno Manhã"
    when 12..17 then "Turno Tarde"
    when 18..23 then "Turno Noite"
    end
  end

  # Turno curto (até 1h) — ex.: 13:00–14:00 ou 23:00–00:00
  def avulsa?
    return false unless starts_at && ends_at
    s, e = slot_minutes
    (e - s) <= 60
  end

  # [início, fim] em minutos no dia; fim ≤ início significa que cruza a meia-noite.
  def slot_minutes
    s = starts_at.hour * 60 + starts_at.min
    e = ends_at.hour * 60 + ends_at.min
    e += 1440 if e <= s
    [s, e]
  end

  def time_range
    "#{starts_at.strftime("%H:%M")}–#{ends_at.strftime("%H:%M")}"
  end

  def cancellable?
    return false if cancelled?
    slot_start = Time.zone.local(date.year, date.month, date.day,
                                 starts_at.hour, starts_at.min)
    lead_hours = ENV.fetch("CANCELLATION_LEAD_HOURS", 48).to_i
    slot_start > lead_hours.hours.from_now
  end

  # Horário do turno já passou em relação a agora.
  def past?
    return false unless date && starts_at
    Time.zone.local(date.year, date.month, date.day, starts_at.hour, starts_at.min) < Time.current
  end

  private

  def not_in_the_past
    errors.add(:base, "Não é possível criar um turno com horário que já passou.") if past?
  end

  def ends_after_starts
    return unless starts_at && ends_at
    # Permite cruzar a meia-noite (ex.: 23:00–00:00); só barra início == fim.
    if (starts_at.hour * 60 + starts_at.min) == (ends_at.hour * 60 + ends_at.min)
      errors.add(:ends_at, "deve ser diferente do horário de início")
    end
  end

  def no_overlapping_slots
    return unless date && starts_at && ends_at && clinic_id

    s1, e1 = slot_minutes
    conflict = clinic.availabilities
      .where(date: date)
      .where.not(id: id)
      .where.not(status: %w[cancelled])
      .any? do |other|
        s2, e2 = other.slot_minutes
        s1 < e2 && s2 < e1
      end

    errors.add(:base, "Já existe um turno neste intervalo de horário") if conflict
  end
end
