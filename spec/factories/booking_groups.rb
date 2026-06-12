FactoryBot.define do
  factory :booking_group do
    association :clinic
    association :dentist, factory: [:user, :dentist]

    subtotal_cents { 30_000 }
    discount_cents { 0 }
    total_cents    { 30_000 }
    status         { "pending" }

    trait :confirmed do
      status { "confirmed" }
    end

    trait :expired do
      status { "expired" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_discount do
      association :discount_rule
      discount_cents { 3_000 }
      total_cents    { 27_000 }
    end

    trait :with_bookings do
      after(:create) do |group|
        availability = create(:availability, clinic: group.clinic, status: "booked")
        create(:booking, clinic: group.clinic, booking_group: group,
               availability: availability, dentist: group.dentist)
      end
    end
  end
end
