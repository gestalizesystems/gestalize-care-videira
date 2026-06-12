FactoryBot.define do
  factory :service do
    association :clinic
    sequence(:name) { |n| "Serviço #{n}" }
    description     { "Descrição do serviço" }
    duration_minutes { 30 }
    price_cents      { 15_000 }
    active           { true }
  end
end
