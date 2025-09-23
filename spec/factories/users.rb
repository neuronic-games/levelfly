FactoryBot.define do
  factory :user do
    email Faker::Internet.email
    password Faker::Internet.password
    default_school factory: :school
    confirmed_at Time.now
  end
end
