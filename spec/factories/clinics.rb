FactoryBot.define do
  factory :clinic do
    sequence(:name)  { |n| "Clínica #{n}" }
    sequence(:cnpj)  { |n| format("%014d", n + 1_000_000) }
    sequence(:email) { |n| "clinic#{n}@example.com" }
    phone { "51999990000" }
  end
end
