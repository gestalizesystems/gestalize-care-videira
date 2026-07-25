FactoryBot.define do
  factory :discount_rule do
    association :clinic
    min_slots      { 2 }
    discount_cents { 1_500 }
    active         { true }

    trait :large do
      min_slots      { 3 }
      discount_cents { 2_250 }
    end

    trait :inactive do
      active { false }
    end
  end
end
