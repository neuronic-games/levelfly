FactoryGirl.define do
  factory :task do
    name Faker::Lorem.sentence
    archived false
  end
end
