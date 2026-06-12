class AdminBookingCreator < ApplicationService
  def initialize(availability:, dentist:)
    @availability = availability
    @dentist      = dentist
  end

  def call
    return failure("Turno não disponível.")  unless @availability.available?
    return failure("Este turno já passou.")   if     @availability.past?
    return failure("Dentista inválido.")      unless @dentist.dentist?

    ActiveRecord::Base.transaction do
      group = BookingGroup.create!(
        clinic:          @availability.clinic,
        dentist:         @dentist,
        subtotal_cents:  @availability.price_cents,
        discount_cents:  0,
        total_cents:     @availability.price_cents,
        status:          "confirmed"
      )

      Booking.create!(
        clinic:         @availability.clinic,
        booking_group:  group,
        availability:   @availability,
        dentist:        @dentist,
        price_cents:    @availability.price_cents,
        status:         "confirmed"
      )

      Payment.create!(
        clinic:       @availability.clinic,
        booking_group: group,
        amount_cents:  @availability.price_cents,
        gateway:       "admin",
        status:        "paid",
        paid_at:       Time.current
      )

      @availability.update!(status: "booked")

      success(group)
    end
  rescue => e
    log_error(e.message)
    failure("Erro ao criar reserva.")
  end
end
