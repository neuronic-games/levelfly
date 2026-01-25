FactoryBot.define do
  factory :course_grade do
    grade { Faker::Number.between(from: 0, to: 100) }
    association :profile
    association :course
  end
end