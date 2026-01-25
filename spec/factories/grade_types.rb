FactoryBot.define do
  factory :grade_type do
    name { Faker::Educator.grade }
    value { Faker::Number.between(from: 0, to: 100) }
  end
end