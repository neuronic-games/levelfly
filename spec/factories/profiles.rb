FactoryBot.define do
  factory :profile do
    full_name Faker::Name.name
    code nil
  end
end
