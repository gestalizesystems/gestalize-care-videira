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

  # Valor total dos insumos (Videira Shop) deste pedido, em centavos.
  def extras_total_cents
    Array(extras).sum { |e| e["price_cents"].to_i * e["quantity"].to_i }
  end

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
    was_pending = pending?
    transaction do
      update!(status: final_status)
      bookings.each do |b|
        b.update!(status: "cancelled")
        b.availability.update!(status: "available")
      end
      # Reserva não paga liberada: devolve o crédito que havia sido aplicado
      # (para reservas confirmadas, o reembolso é feito pelo CreditIssuer).
      refund_applied_credit! if was_pending
    end
  end

  # Crédito usado nesta reserva = total − o que faltava pagar por fora (Pix).
  def refund_applied_credit!
    external_due = payments.where.not(gateway: "credit").sum(:amount_cents)
    applied      = total_cents.to_i - external_due.to_i
    return if applied <= 0

    Credit.create!(
      user:         dentist,
      clinic:       clinic,
      amount_cents: applied,
      reason:       "Estorno de crédito (reserva não paga)"
    )
  end
end
