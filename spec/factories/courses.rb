FactoryGirl.define do
  factory :course do
    name { Faker::Educator.subject }
    code { Faker::Alphanumeric.alpha(number: 3) }
  end
end
