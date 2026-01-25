class Participant < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :profile

  attr_accessor :xp, :total_xp, :course_outcomes, :grade, :task_grade, :task_outcome_grade, :like_received,
                :badge_count, :badge_image_urls, :avatar_badge_ids, :notes

  @@profile_type_master = 'M'
  cattr_accessor :profile_type_master

  @@profile_type_student = 'S'
  cattr_accessor :profile_type_student

  @@member_of_course = 'Course'
  cattr_accessor :member_of_course

  # Participant.is_member_of(my_course.class.name, my_course.id, my_profile)
  def self.is_member_of(target_type, target_id, profile_id, profile_type = %w[M S])
    p = Participant.where(['target_type = ? and target_id = ? and profile_id = ? and profile_type in (?)', target_type,
                           target_id, profile_id, profile_type]).first

    !p.nil?
  end

  def as_json(options = {})
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || {}).merge({
                                  methods: %i[
                                    xp
                                    total_xp
                                    course_outcomes
                                    grade
                                    task_grade
                                    task_outcome_grade
                                    like_received
                                    badge_count
                                    badge_image_urls
                                    avatar_badge_ids
                                    notes
                                  ]
                                }))
  end
end
