FactoryBot.define do
  factory :user do
    association :clinic
    sequence(:name)  { |n| "Usuário #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:cpf)   { |n| format("%011d", n) }
    password     { "Senha@1234!" }
    role         { "dentist" }
    cro          { "CRO-CE 12345" }
    phone        { "85999000001" }
    confirmed_at { Time.current }

    trait :owner do
      role { "owner" }
      sequence(:name) { |n| "Owner #{n}" }
    end

    trait :dentist do
      role { "dentist" }
      sequence(:name) { |n| "Dr. #{n}" }
    end

    trait :with_google do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google_uid_#{n}" }
    end
  end
end
