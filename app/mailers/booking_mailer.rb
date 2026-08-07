class BookingMailer < ApplicationMailer
  def confirmation(booking_group)
    @group   = booking_group
    @dentist = booking_group.dentist
    mail(to: @dentist.email, subject: "Pagamento confirmado — Videira Clinic")
  end

  def cancellation(booking_group)
    @group   = booking_group
    @dentist = booking_group.dentist
    mail(to: @dentist.email, subject: "Reserva cancelada — Videira Clinic")
  end

  def credit_issued(user, credit)
    @user   = user
    @credit = credit
    mail(to: user.email, subject: "Crédito disponível — Videira Clinic")
  end

  def admin_notification(booking_group)
    @group   = booking_group
    @dentist = booking_group.dentist
    owner    = booking_group.clinic.users.find_by(role: "owner")
    return if owner.nil?

    mail(to: owner.email, subject: "Nova reserva confirmada — #{@dentist.name}")
  end

  def admin_cancellation_notification(booking, group)
    @booking = booking
    @group   = group
    @dentist = group.dentist
    owner    = group.clinic.users.find_by(role: "owner")
    return if owner.nil?

    mail(to: owner.email, subject: "Reserva cancelada — #{@dentist.name}")
  end

  def admin_slot_change_notification(booking, old_availability)
    @booking = booking
    @old_av  = old_availability
    @new_av  = booking.availability
    @group   = booking.booking_group
    @dentist = @group.dentist
    owner    = @group.clinic.users.find_by(role: "owner")
    return if owner.nil?

    mail(to: owner.email, subject: "Turno alterado — #{@dentist.name}")
  end

  def admin_extras_notification(payment)
    @payment = payment
    @group   = payment.booking_group
    @dentist = @group.dentist
    owner    = @group.clinic.users.find_by(role: "owner")
    return if owner.nil?

    mail(to: owner.email, subject: "Insumos comprados — #{@dentist.name}")
  end
end
