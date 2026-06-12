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

      total = availabilities.sum(&:price_cents)

      group = BookingGroup.create!(
        clinic:         @clinic,
        dentist:        @dentist,
        subtotal_cents: total,
        discount_cents: 0,
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
