class Badge < ActiveRecord::Base
belongs_to :badge_image

  def self.load_all_badges(profile)
    @badges = Badge.where("school_id = ? and (creator_profile_id = ? or creator_profile_id IS NULL)",profile.school_id,profile.id)
    @last_used = Badge.select("distinct badges.id, badges.name, badges.badge_image_id").joins("inner join avatar_badges on badge_id = badges.id").where("avatar_badges.giver_profile_id = ?",profile.id).order("avatar_badges.created_at desc").limit("4")
    return @badges,@last_used
  end

  def self.check_badge(profile_id,badge_id,course_id)
    @badge = AvatarBadge.find(:first, :conditions=>["profile_id = ? and badge_id = ? and course_id = ?",profile_id,badge_id,course_id])
    if @badge.nil?
      return true
    else
      return false
    end
  end

end
