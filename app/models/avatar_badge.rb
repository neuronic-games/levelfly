class AvatarBadge < ActiveRecord::Base
  belongs_to :badge
  belongs_to :profile
  belongs_to :giver_profile, class_name: :Profile
  belongs_to :course

  # Add a badge to the specified profile
  def self.add_badge(profile_id, badge_id, course_id = nil, giver_profile_id = nil)
    status = nil
    @student = Profile.find(profile_id)
    @badge = Badge.find(badge_id)
    @avatar_badge = AvatarBadge.new
    @avatar_badge.profile_id = profile_id
    @avatar_badge.badge_id  = badge_id
    @avatar_badge.course_id = course_id
    @avatar_badge.giver_profile_id = giver_profile_id
    status = true if @avatar_badge.save
    @student.badge_count += 1
    @student.save

    # Game badges do not have a giver or course. We don't send out notifications
    # because there may be a lot of game badges.
    return status if giver_profile_id.nil? || course_id.nil?

    @current_user = Profile.find_by_id(giver_profile_id)
    course = Course.find_by_id(course_id)
    content = "Congratulations! You have received a badge: #{@badge.name}"
    UserMailer.new_badge(@student, @current_user, @current_user.school, course, @badge.name).deliver
    Message.send_notification(giver_profile_id, content, @student.id)

    Pusher.trigger_async("private-my-channel-#{profile_id}", 'new_message', {})

    status
  end
end
