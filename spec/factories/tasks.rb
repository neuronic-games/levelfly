FactoryBot.define do
  factory :task do
    name Faker::Company.bs
    archived false
  end
end
