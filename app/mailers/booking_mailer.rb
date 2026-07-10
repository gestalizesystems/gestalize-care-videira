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
end
