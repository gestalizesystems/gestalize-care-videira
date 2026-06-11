class AdminBookingSlotChanger < ApplicationService
  def initialize(booking:, new_availability:)
    @booking = booking
    @new_av  = new_availability
  end

  def call
    return failure("Selecione um turno.")     unless @booking && @new_av
    return failure("Turno indisponível.")     unless @new_av.available?
    old_av = @booking.availability
    return failure("Selecione um turno diferente do atual.") if old_av&.id == @new_av.id

    ActiveRecord::Base.transaction do
      @new_av.update!(status: "booked")
      old_av&.update!(status: "available")
      @booking.update!(availability: @new_av, price_cents: @new_av.price_cents)

      group = @booking.booking_group
      total = group.bookings.sum(:price_cents)
      group.update!(subtotal_cents: total, total_cents: total - group.discount_cents.to_i)

      success(group)
    end
  rescue => e
    log_error(e.message)
    failure("Erro ao alterar turno.")
  end
end
