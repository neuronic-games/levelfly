FactoryBot.define do
  factory :setting do
    name { Faker::Alphanumeric.alpha(number: 10) }
    value { Faker::Alphanumeric.alpha(number: 10) }
  end
end
