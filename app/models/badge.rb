class Badge < ActiveRecord::Base
belongs_to :badge_image
has_many :avatar_badges

  def self.load_all_badges(profile)
    @badges = Badge.where("school_id = ? and (creator_profile_id = ? or creator_profile_id IS NULL)",profile.school_id,profile.id).order("created_at desc")
    badge_ids = AvatarBadge.find(:all, :select=>"badge_id", :conditions=>["giver_profile_id = ?",profile.id], :order => "created_at desc").collect(&:badge_id)
    badge_ids=badge_ids.uniq
    ids = badge_ids.in_groups_of(4)
    @last_used = Badge.find(:all, :conditions => ["id in (?)",ids[0]])
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

  def self.gold_outcome_badge(outcome_name,badge_creator)
    @badge = self.find_by_name("Gold Medal in #{outcome_name}")
    return @badge if @badge
    @badge = self.new
    @badge.name = "Gold Medal in #{outcome_name}"
    @badge.descr = "Congratulations! You received this award because you were among the highest-performing students in your course for the learning outcome '#{outcome_name}'."
    @badge.badge_image_id = 42
    @badge.school_id = badge_creator.school_id
    @badge.creator_profile_id = badge_creator.id
    if @badge.save
      return @badge
    end
  end

end
