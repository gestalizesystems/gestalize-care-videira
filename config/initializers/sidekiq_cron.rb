Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      "expire_payments" => {
        "cron"  => "* * * * *",
        "class" => "ExpirePaymentsJob"
      }
    )
  end
end
