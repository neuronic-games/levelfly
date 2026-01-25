FactoryBot.define do
  factory :category do
    name { Faker::Hipster.word }
    percent_value { Faker::Number.between(from: 0, to: 100) }
  end
end
