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
  
  def self.badge_count(profile_id)
    @badge = []
    @badge_ids = AvatarBadge.find(:all, :select => "id, badge_id", :conditions =>["profile_id = ? ",profile_id])
    puts"#{@badge_ids}==="
    # if @badge_ids and !@badge_ids.nil?
      # @badge_ids.each do |b|
        # badge = Badge.find(:first, :conditions=>["id = ? ",b.badge_id],:order => "created_at DESC")
        # @badge.push(badge)           
      # end
    # end
    return @badge_ids
  end
  
  def self.badge_detail(badge_id)
    badge = Badge.find(:first, :conditions=>["id = ? ",badge_id])
    return badge
  end

end
