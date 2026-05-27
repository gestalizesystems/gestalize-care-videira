class BookingMailer < ApplicationMailer
  def confirmation(booking_group)
    @group   = booking_group
    @dentist = booking_group.dentist
    mail(to: @dentist.email, subject: "Pagamento confirmado — Videira Dental")
  end

  def cancellation(booking_group)
    @group   = booking_group
    @dentist = booking_group.dentist
    mail(to: @dentist.email, subject: "Reserva cancelada — Videira Dental")
  end

  def credit_issued(user, credit)
    @user   = user
    @credit = credit
    mail(to: user.email, subject: "Crédito disponível — Videira Dental")
  end
end
