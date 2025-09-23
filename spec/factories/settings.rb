FactoryGirl.define do
  factory :setting do
    name { Faker::Lorem.word }
    value { Faker::Lorem.word }
  end
end
