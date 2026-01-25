FactoryBot.define do
  factory :participant

  trait :course_master do
    target_type { 'Course' }
    profile_type { 'M' }
  end

  trait :course_student do
    target_type { 'Course' }
    profile_type { 'S' }
  end
end
