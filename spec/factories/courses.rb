FactoryBot.define do
  factory :course do
    name { Faker::Educator.subject }
    code { Faker::Alphanumeric.alpha(number: 3) }

    removed { false }

    trait :group do
      name { Faker::Alphanumeric.alpha(number: 10) }
      parent_type { Course.parent_type_group }
    end
  end
end
