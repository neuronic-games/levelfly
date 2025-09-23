FactoryGirl.define do
  factory :reward do
    xp { Faker::Number.within(range: 0..2000) }
  end
end
