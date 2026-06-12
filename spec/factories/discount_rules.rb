FactoryBot.define do
  factory :discount_rule do
    association :clinic
    min_slots        { 2 }
    discount_percent { 10 }
    active           { true }

    trait :large do
      min_slots        { 3 }
      discount_percent { 15 }
    end

    trait :inactive do
      active { false }
    end
  end
end
