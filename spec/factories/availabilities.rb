FactoryBot.define do
  sequence(:av_start_hour) { |n| format("%02d", 6 + (n % 12)) }

  factory :availability do
    association :clinic
    association :service
    association :dentist, factory: [:user, :dentist]

    date        { Date.current + 3.days }
    starts_at   { "#{generate(:av_start_hour)}:00" }
    ends_at     { format("%02d:00", starts_at.split(":").first.to_i + 1) }
    status      { "available" }
    price_cents { 15_000 }

    trait :booked do
      status { "booked" }
    end

    trait :past do
      date { Date.current - 1.day }
    end

    trait :within_lead_time do
      date      { Date.current }
      starts_at { 2.hours.from_now.strftime("%H:%M") }
      ends_at   { 2.hours.from_now.advance(minutes: 30).strftime("%H:%M") }
    end
  end
end
