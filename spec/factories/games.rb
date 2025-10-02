FactoryBot.define do
  factory :game do
    name { Faker::Game.unique.title }
    handle { Faker::Alphanumeric.alpha(number: 3) }
    download_links { { 'linux' => Faker::Internet.url } }
  end
end
