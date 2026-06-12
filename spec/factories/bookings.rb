FactoryBot.define do
  factory :booking do
    association :clinic
    association :booking_group
    association :availability
    association :dentist, factory: [:user, :dentist]

    price_cents { 15_000 }
    status      { "pending" }

    trait :confirmed do
      status { "confirmed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
