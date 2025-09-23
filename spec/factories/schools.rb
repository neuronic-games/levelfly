FactoryBot.define do
  factory :school do
    name { Faker::University.name }
    code { Faker::Alphanumeric.alpha(number: 5) }
  end
end
