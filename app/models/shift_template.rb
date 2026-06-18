class ShiftTemplate < ApplicationRecord
  include MoneyConvertible
  money_field :price

  belongs_to :clinic

  validates :starts_at, :ends_at, presence: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:starts_at) }

  # Rótulo derivado do horário (mesma regra de Availability).
  def label
    return "Aluguel de Sala" unless starts_at
    return "Hora Avulsa" if avulsa?
    return "Diária" if diaria?
    case starts_at.hour
    when  0..5  then "Turno Madrugada"
    when  6..11 then "Turno Manhã"
    when 12..17 then "Turno Tarde"
    when 18..23 then "Turno Noite"
    end
  end

  def avulsa?
    return false unless starts_at && ends_at
    (slot_minutes_duration) <= 60
  end

  # Diária — turno longo (8h ou mais), ex.: 08:00–18:00
  def diaria?
    return false unless starts_at && ends_at
    (slot_minutes_duration) >= 480
  end

  def slot_minutes_duration
    s = starts_at.hour * 60 + starts_at.min
    e = ends_at.hour * 60 + ends_at.min
    e += 1440 if e <= s
    e - s
  end

  def time_range
    "#{starts_at.strftime('%H:%M')}–#{ends_at.strftime('%H:%M')}"
  end
end
