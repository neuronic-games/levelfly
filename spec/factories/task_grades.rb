FactoryBot.define do
  factory :task_grade do
    grade { Faker::Number.between(from: 0.00, to: 100.00) }
  end
end

