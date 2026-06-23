class AdminBookingGroupCreator < ApplicationService
  def initialize(availability_ids:, dentist:)
    @availability_ids = Array(availability_ids)
    @dentist          = dentist
    @clinic           = Availability.find_by(id: @availability_ids.first)&.clinic
  end

  def call
    return failure("Clínica não encontrada.")  unless @clinic
    return failure("Dentista inválido.")        unless @dentist.dentist?
    return failure("Nenhum horário selecionado.") if @availability_ids.empty?

    ActiveRecord::Base.transaction do
      availabilities = @clinic.availabilities
        .where(id: @availability_ids, status: "available")
        .lock("FOR UPDATE")
        .to_a

      if availabilities.size != @availability_ids.size
        return failure("Um ou mais horários não estão mais disponíveis.")
      end

      if availabilities.combination(2).any? { |a, b| a.overlaps?(b) }
        return failure("Há horários selecionados que se sobrepõem. Remova um deles.")
      end

      subtotal = availabilities.sum(&:price_cents)
      # Desconto pessoal do dentista por turno elegível (não conta avulsa/diária).
      eligible = availabilities.reject { |a| a.avulsa? || a.diaria? }.size
      discount = [@dentist.discount_per_slot_cents.to_i * eligible, subtotal].min
      total    = subtotal - discount

      group = BookingGroup.create!(
        clinic:         @clinic,
        dentist:        @dentist,
        subtotal_cents: subtotal,
        discount_cents: discount,
        total_cents:    total,
        status:         "confirmed"
      )

      availabilities.each do |av|
        Booking.create!(
          clinic:        @clinic,
          booking_group: group,
          availability:  av,
          dentist:       @dentist,
          price_cents:   av.price_cents,
          status:        "confirmed"
        )
        av.update!(status: "booked")
      end

      Payment.create!(
        clinic:        @clinic,
        booking_group: group,
        amount_cents:  total,
        gateway:       "admin",
        status:        "paid"
      )

      success(group)
    end
  rescue => e
    log_error(e.message)
    failure("Erro ao criar reserva.")
  end
end
