class BookingGroupCreator < ApplicationService
  class SlotUnavailableError < StandardError; end
  class PaymentError < StandardError; end

  def initialize(user:, availability_ids:)
    @user             = user
    @availability_ids = Array(availability_ids)
    @clinic           = Availability.find_by(id: @availability_ids.first)&.clinic
  end

  def call
    return failure("Horário inválido ou não encontrado.") unless @clinic
    return failure("Selecione ao menos um horário.") if @availability_ids.empty?

    calc = DiscountCalculator.call(availability_ids: @availability_ids, clinic: @clinic)
    return failure("Erro ao calcular preços.") unless calc.success?

    pricing = calc.value
    if pricing[:availabilities].size != @availability_ids.size
      return failure("Um ou mais horários não estão mais disponíveis. Atualize seu carrinho.")
    end

    group   = nil
    payment = nil

    ActiveRecord::Base.transaction do
      availabilities = Availability
        .where(id: @availability_ids, clinic: @clinic, status: "available")
        .lock("FOR UPDATE")
        .load

      if availabilities.size != @availability_ids.size
        raise SlotUnavailableError, "Um ou mais horários foram reservados por outra pessoa."
      end

      group = BookingGroup.create!(
        clinic:         @clinic,
        dentist:        @user,
        discount_rule:  pricing[:discount_rule],
        subtotal_cents: pricing[:subtotal_cents],
        discount_cents: pricing[:discount_cents],
        total_cents:    pricing[:total_cents],
        status:         "pending"
      )

      availabilities.each do |av|
        Booking.create!(
          clinic:        @clinic,
          booking_group: group,
          availability:  av,
          dentist:       @user,
          price_cents:   av.price_cents,
          status:        "pending"
        )
        av.update!(status: "booked")
      end

      credits_applied = apply_available_credits(group, pricing[:total_cents])
      amount_due      = pricing[:total_cents] - credits_applied

      payment = if amount_due.zero?
        confirm_fully_credit_paid(group, credits_applied)
      else
        create_pix_payment(group, amount_due)
      end
    end

    success(group.reload)
  rescue SlotUnavailableError, PaymentError => e
    failure(e.message)
  rescue ActiveRecord::RecordNotUnique
    failure("Um ou mais horários já foram reservados. Por favor, atualize sua seleção.")
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def apply_available_credits(group, total_cents)
    credits = Credit.available
      .where(user: @user, clinic: @clinic)
      .lock("FOR UPDATE")
      .order(:created_at)
      .to_a

    return 0 if credits.empty?

    applied = 0
    credits.each do |credit|
      break if applied >= total_cents
      credit.update!(used_at: Time.current, used_on_booking_group: group)
      applied += credit.amount_cents
    end

    [applied, total_cents].min
  end

  def confirm_fully_credit_paid(group, credits_applied)
    group.update!(status: "confirmed")
    group.bookings.update_all(status: "confirmed")

    Payment.create!(
      clinic:        @clinic,
      booking_group: group,
      gateway:       "credit",
      amount_cents:  credits_applied,
      status:        "paid",
      paid_at:       Time.current
    )
  end

  def create_pix_payment(group, amount_due)
    pix = MercadoPago::PixCreator.call(group, amount_cents: amount_due)
    raise PaymentError, pix.error unless pix.success?

    Payment.create!(
      clinic:        @clinic,
      booking_group: group,
      gateway:       "mercadopago",
      gateway_id:    pix.value[:gateway_id],
      pix_qr_code:   pix.value[:pix_qr_code],
      pix_qr_url:    pix.value[:pix_qr_url],
      amount_cents:  amount_due,
      expires_at:    pix.value[:expires_at],
      status:        "pending"
    )
  end
end
