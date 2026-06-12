FactoryBot.define do
  factory :payment do
    association :clinic
    association :booking_group

    amount_cents { 30_000 }
    status       { "pending" }
    gateway      { "infinitepay" }
    checkout_url { "https://checkout.infinitepay.io/test-#{SecureRandom.hex(6)}" }
    expires_at   { 30.minutes.from_now }

    trait :paid do
      status     { "paid" }
      paid_at    { Time.current }
      gateway_id { "txn-#{SecureRandom.hex(8)}" }
    end

    trait :expired do
      status     { "expired" }
      expires_at { 1.hour.ago }
    end

    trait :expired_unpaid do
      status     { "pending" }
      expires_at { 1.hour.ago }
    end
  end
end
