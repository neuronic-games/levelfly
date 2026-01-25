FactoryBot.define do
  factory :game do
    name { Faker::Game.unique.title }
    handle { Faker::Alphanumeric.alpha(number: 3) }
    download_links do
      {
        'ios' => Faker::Internet.url,
        'windows' => Faker::Internet.url,
        'mac' => Faker::Internet.url,
        'linux' => Faker::Internet.url,
        'guide' => Faker::Internet.url
      }
    end
  end
end
