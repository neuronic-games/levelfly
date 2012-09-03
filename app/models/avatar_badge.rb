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
    content = "Congrtulation! You are received #{@badge.name} badge"
    Message.send_notification(giver_profile_id,content,@student.id)
    return status
  end
end
