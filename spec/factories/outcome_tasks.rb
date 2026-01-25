FactoryBot.define do
  factory :outcome_task do
    points_percentage { Faker::Number.between(from: 1.0, to: 100.0) }
  end
end
