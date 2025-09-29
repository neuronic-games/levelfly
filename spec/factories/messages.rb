FactoryBot.define do
  factory :message do
    content { Faker::Lorem.sentence }
    starred { false }
  end
end
