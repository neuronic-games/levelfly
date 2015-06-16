class AvatarBadge < ActiveRecord::Base
belongs_to :badges

  def self.add_badge(profile_id,badge_id,course_id,giver_profile_id)
    status = nil
    @student = Profile.find(profile_id)
    @badge = Badge.find(badge_id)
    @avatar_badge = AvatarBadge.new
    @avatar_badge.profile_id = profile_id
    @avatar_badge.badge_id  = badge_id
    @avatar_badge.course_id = course_id
    @avatar_badge.giver_profile_id = giver_profile_id
    if @avatar_badge.save
      status = true
    end
    @student.badge_count+=1
    @student.save
    @current_user = Profile.find_by_id(giver_profile_id)
    course = Course.find_by_id(course_id)
    content = "Congratulations! You have received a badge: #{@badge.name}"
    UserMailer.new_badge(@student,@current_user,@current_user.school,course,@badge.name).deliver
    Message.send_notification(giver_profile_id,content,@student.id)

    Pusher.trigger_async("private-my-channel-#{profile_id}", 'new_message',{})

    return status
  end
end
