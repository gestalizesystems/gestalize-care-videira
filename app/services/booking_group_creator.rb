class BookingGroupCreator < ApplicationService
  class SlotUnavailableError < StandardError; end
  class PaymentError < StandardError; end

  def initialize(user:, availability_ids:)
    @user             = user
    @availability_ids = Array(availability_ids)
    @clinic           = user.clinic
  end

  def call
    return failure("Sua conta não está associada a uma clínica.") unless @clinic
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
      # Load records with FOR UPDATE before calling .size to avoid
      # PG::FeatureNotSupported: COUNT(*) FOR UPDATE is not allowed.
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

      pix = MercadoPago::PixCreator.call(group)
      raise PaymentError, pix.error unless pix.success?

      payment = Payment.create!(
        clinic:        @clinic,
        booking_group: group,
        gateway:       "mercadopago",
        gateway_id:    pix.value[:gateway_id],
        pix_qr_code:   pix.value[:pix_qr_code],
        pix_qr_url:    pix.value[:pix_qr_url],
        amount_cents:  group.total_cents,
        expires_at:    pix.value[:expires_at],
        status:        "pending"
      )
    end

    success(group.reload)
  rescue SlotUnavailableError, PaymentError => e
    failure(e.message)
  rescue ActiveRecord::RecordNotUnique
    failure("Um ou mais horários já foram reservados. Por favor, atualize sua seleção.")
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end
end
