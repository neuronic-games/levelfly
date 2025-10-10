FactoryBot.define do
  factory :avatar do
    skin { 3 }

    prop { Faker::Alphanumeric.alpha(number: 64) }
    hat { Faker::Alphanumeric.alpha(number: 64) }
    hair { Faker::Alphanumeric.alpha(number: 64) }
    glasses { Faker::Alphanumeric.alpha(number: 64) }
    facial_hair { Faker::Alphanumeric.alpha(number: 64) }
    facial_marks { Faker::Alphanumeric.alpha(number: 64) }
    earrings { Faker::Alphanumeric.alpha(number: 64) }
    head { Faker::Alphanumeric.alpha(number: 64) }
    top { Faker::Alphanumeric.alpha(number: 64) }
    necklace { Faker::Alphanumeric.alpha(number: 64) }
    bottom { Faker::Alphanumeric.alpha(number: 64) }
    shoes { Faker::Alphanumeric.alpha(number: 64) }
    hair_back { Faker::Alphanumeric.alpha(number: 64) }
    hat_back { Faker::Alphanumeric.alpha(number: 64) }
    body { Faker::Alphanumeric.alpha(number: 64) }
    background { Faker::Alphanumeric.alpha(number: 64) }
  end
end
