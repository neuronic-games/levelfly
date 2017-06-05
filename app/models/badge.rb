# Badges given to people
class Badge < ActiveRecord::Base
  belongs_to :badge_image
  has_many :avatar_badges

  @@gold_badge = 'gold_badge.png'
  cattr_accessor :gold_badge

  # Read badges for specified profile
  def self.load_all_badges(profile)
    gold_image_id = BadgeImage.find_by_image_file_name(Badge.gold_badge)
    gold_image_id = gold_image_id ? gold_image_id.id : 0
    @badges = Badge.where("school_id = ? and (creator_profile_id = ? or creator_profile_id IS NULL) and badge_image_id not in (?) and archived != true",profile.school_id,profile.id,gold_image_id).order("created_at desc")
    badge_ids = AvatarBadge.find(:all, :select=>"badge_id", :conditions=>["giver_profile_id = ?",profile.id], :order => "created_at desc").collect(&:badge_id)
    badge_ids=badge_ids.uniq
    ids = badge_ids.in_groups_of(4)
    @last_used = Badge.find(:all, :conditions => ["id in (?) and badge_image_id not in (?) and archived != true",ids[0],gold_image_id])
    return @badges,@last_used
  end

  # Returns true if the given profile does not have the specified badge for the course
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
  
  def self.outcome_rating_badge(rating)
    return 'oB_box001_gold' if rating >= 2.5
    return 'oB_box001_silver' if rating >= 1.5
    return 'oB_box001'
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
    gold_badge = BadgeImage.find_by_image_file_name(Badge.gold_badge)
    gold_badge = BadgeImage.create(:image_file_name => Badge.gold_badge, :image_content_type =>"image/png") unless gold_badge
    return gold_badge.id
  end

  # Use this to find (and create) a game badge
  def self.find_create_game_badge(game_id, name, descr = nil, badge_image_id = nil)
    badge = Badge.where(name: name, quest_id: game_id).first
    if badge.nil?    
      new_badge = Badge.new
      new_badge.name = name
      new_badge.descr = descr
      new_badge.badge_image_id = badge_image_id.nil? ? 1 : badge_image_id
      default_badge_image = BadgeImage.find_by_image_file_name("trophy5.png")
      new_badge.available_badge_image_id = default_badge_image.id
      new_badge.quest_id = game_id  # We can use quest_id for storing game_id for now. But if we want to use if for other purposes, we need quest_type
      badge = new_badge
    else
      badge.descr = descr if badge.descr.blank?
      # If the image ID is passed, the use system badges. available_badge_image_id is only used for system badges
      if !badge_image_id.nil?
        badge.available_badge_image_id = badge.badge_image_id
      end
    end
    
    badge.save
    
    return badge
  end
  
  def image_url
    return badge_image ? badge_image.image_file_path : BadgeImage.blank
  end

  def available_image_url
    if self.available_badge_image_id.present?
      return BadgeImage.available_image_by_badge(available_badge_image_id)
    end
    if (self.badge_image and self.badge_image.image_file_name == Badge.gold_badge)
      return self.image_url
    end
    return self.try(:badge_image).try(:image).try(:url)
  end

end
