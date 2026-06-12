class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "no-reply@videiradental.com.br")
  layout "mailer"
end
