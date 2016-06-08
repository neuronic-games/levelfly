class Badge < ActiveRecord::Base
  belongs_to :badge_image
  has_many :avatar_badges

  def self.load_all_badges(profile)
    gold_image_id = BadgeImage.find_by_image_file_name("gold_badge.png")
    gold_image_id = gold_image_id ? gold_image_id.id : 0
    @badges = Badge.where("school_id = ? and (creator_profile_id = ? or creator_profile_id IS NULL) and badge_image_id not in (?) and archived != true",profile.school_id,profile.id,gold_image_id).order("created_at desc")
    badge_ids = AvatarBadge.find(:all, :select=>"badge_id", :conditions=>["giver_profile_id = ?",profile.id], :order => "created_at desc").collect(&:badge_id)
    badge_ids=badge_ids.uniq
    ids = badge_ids.in_groups_of(4)
    @last_used = Badge.find(:all, :conditions => ["id in (?) and badge_image_id not in (?) and archived != true",ids[0],gold_image_id])
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
    @badge.badge_image_id = Badge.gold_badge_image
    @badge.school_id = badge_creator.school_id
    @badge.creator_profile_id = badge_creator.id
    if @badge.save
      return @badge
    end
  end

  def self.gold_badge_image
    gold_badge = BadgeImage.find_by_image_file_name("gold_badge.png")
    gold_badge = BadgeImage.create(:image_file_name => 'gold_badge.png', :image_content_type =>"image/png") unless gold_badge
    return gold_badge.id
  end

  # Use this to find (and create) a game badge
  def self.find_create_game_badge(game_id, name, descr = nil, badge_image_id = nil)
    badge = Badge.where(name: name, quest_id: game_id).first
    if badge.nil?    
      badge = Badge.new
      badge.name = name
      badge.descr = descr
      badge.badge_image_id = badge_image_id.nil? ? 1 : badge_image_id
      badge.available_badge_image_id = badge.badge_image_id
      badge.quest_id = game_id  # We can use quest_id for storing game_id for now. But if we want to use if for other purposes, we need quest_type
    else
      badge.descr = descr unless descr.blank?
      badge.badge_image_id = badge_image_id unless badge_image_id.to_i == 0
      badge.available_badge_image_id = badge.badge_image_id
    end
    
    badge.save
    
    return badge
  end
  
  def image_url
    return badge_image.image_file_path
  end

  def available_image_url
    return badge_image.available_image_by_badge(available_badge_image_id)
  end

end
