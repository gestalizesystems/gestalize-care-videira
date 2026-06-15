class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Videira Clinic <nao-responda@videiraclinic.com.br>")
  layout "mailer"
end
