Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      "expire_payments" => {
        "cron"  => "* * * * *",
        "class" => "ExpirePaymentsJob"
      },
      # Gera os turnos recorrentes para o próximo dia da janela (todo dia 03:10)
      "generate_recurring_shifts" => {
        "cron"  => "10 3 * * *",
        "class" => "GenerateRecurringShiftsJob"
      }
    )
  end
end
