FactoryBot.define do
  factory :game do
    name { Faker::Game.title }
    handle { Faker::Alphanumeric.alpha(number: 3) }
  end
end
