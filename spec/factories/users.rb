FactoryGirl.define do

  factory :user do
    email 'admin@test-admin.com'
    password '111111'
    default_school_id 2
    confirmed_at Time.now
  end

  factory :profile do
    full_name 'Admin Test'
    school_id 2
    user
  end

  ############

  factory :user_one, class: User do
    email "admin@testing.com"
    password "111111"
    default_school_id 2
    confirmed_at Time.now
  end

  factory :profile_one, class: Profile do
    full_name 'User One'
    school_id 2
    association :user, factory: :user_one
  end

  # ##########

  factory :user_two, class: User do
    email 'user@email.com'
    password '111111'
    default_school_id 2
    confirmed_at Time.now
  end

  factory :profile_two, class: Profile do
    full_name 'User Two'
    school_id 2
    association :user, factory: :user_two
  end

end
