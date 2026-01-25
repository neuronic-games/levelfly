FactoryBot.define do
  factory :outcome do
    name { Faker::Verb.base }
    descr { Faker::Hipster.sentence }

    shared { false }
  end
end
