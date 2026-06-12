FactoryBot.define do
  factory :credit do
    association :clinic
    association :user, factory: [:user, :dentist]

    amount_cents { 10_000 }
    reason       { "Cancelamento de reserva" }

    trait :used do
      used_at { Time.current }
    end
  end
end
