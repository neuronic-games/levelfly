FactoryBot.define do
  factory :badge do
    name { Faker::Lorem.word }
    descr { Faker::Lorem.sentence }
    school_id { 1 }
    creator_profile_id { 1 }
  end
end