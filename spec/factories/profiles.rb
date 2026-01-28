FactoryBot.define do
  factory :profile do
    id { Faker::Number.unique.number(digits: 9) }

    full_name { Faker::Name.name }
    code { nil }

    avatar
  end
end
