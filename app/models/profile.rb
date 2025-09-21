class Profile < ActiveRecord::Base
  has_one :avatar
  belongs_to :major
  belongs_to :school
  belongs_to :user
  belongs_to :role_name

  has_many :participants
	has_many :task_participants
  has_many :profile_actions

  has_many :feats
  has_many :outcome_feats
  has_many :game_score_leaders
  
  has_many :avatar_badges
  
  has_many :messages

  attr_accessor :rank
  
  @master_course_id_list = nil
  
  acts_as_taggable

  scope :course_participants, ->(course_id, section_type) {
    includes(:participants, :user).references(:participants).where(
      "participants.target_id = ? AND participants.target_type IN (?) AND participants.profile_type IN ('S') AND users.status != 'D'", 
      course_id, 
      section_type
    ).order(:full_name, 'users.email')
  }
  scope :course_participants_with_master, ->(course_id, section_type) {
    includes(:participants, :user).where("participants.target_id = ? AND participants.target_type IN (?) AND participants.profile_type IN ('S','M') AND users.status != 'D'", course_id, section_type).order("users.last_sign_in_at DESC, full_name")
  }

  def self.course_master_of(course_id)
    includes(:participants).references(:participants).where("participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", course_id).first
  end
  
  # Cache the course list as well
  def find_course_id_master_of
    return @master_course_id_list unless @master_course_id_list.nil?
    course_id_list = Participant.where(profile_id: self.id, target_type: Participant.member_of_course, profile_type: Participant.profile_type_master).pluck(:target_id)
    @master_course_id_list = Course.where(course_id: course_id_list, archived: false, removed: false, school_id: self.school_id, course_id: 0).pluck(:id)
    return @master_course_id_list
  end

  def self.demo_profile
    demo = School.where(handle: 'demo').first
  Profile.where(:first, :conditions => ["code = ? and school_id = ?", 'DEFAULT', demo.id], :include => [:avatar]).first
  end

  def self.default_avatar_image
    return ENV["URL"] + '/images/wardrobe/null_profile.png'
  end
  
  def visible_avatar_image(viewer_profile_id, course_id = nil)
     return self.image_file_name if is_public
     
     return self.image_file_name if self.id == viewer_profile_id
     
     viewer_profile = Profile.find(viewer_profile_id)
     return self.image_file_name if viewer_profile.has_role(Role.edit_user)
     
     # Are you a student in the viewer's course
     return self.image_file_name if course_id and Course.is_owner?(course_id, viewer_profile_id)
     
     return Profile.default_avatar_image
  end

  def visible_name_and_image(viewer_profile_id, course_id = nil)
     return {name: self.full_name, image: self.image_file_name} if is_public
     
     return {name: self.full_name, image: self.image_file_name} if self.id == viewer_profile_id

     if not viewer_profile_id.blank?
       viewer_profile = Profile.find(viewer_profile_id)
       return {name: self.full_name, image: self.image_file_name} if viewer_profile.has_role(Role.edit_user)
     
       # Are you a student in the viewer's course
       return {name: self.full_name, image: self.image_file_name} if course_id and Course.is_owner?(course_id, viewer_profile_id)
     end
     
     return {name: 'Private', image: Profile.default_avatar_image}
  end

  # Find the profile for this user in given school. If it doesn't exist, create a new profile using the DEFAULT
  # template for this school.
  def self.create_for_user(user_id, school_id, default = "DEFAULT", role_name = nil)
    profile = Profile.where("user_id = ? and school_id = ?", user_id, school_id).first
    if profile.nil?
      new_profile = Profile.where(["code = ? and school_id = ?", default, school_id])
        .includes([:avatar])
        .first

      if default == 'DEFAULT' and new_profile.nil?
        new_profile = Profile.demo_profile()
        new_profile.school_id = school_id
      end
      profile = new_profile.dup
      profile.user_id = user_id
      profile.code = nil

      if role_name.nil?
        # Create a Teacher in the demo school, or a Student in all other schools
        demo_school = School.find_by_handle("demo")
        if not demo_school.nil? and school_id == demo_school.id
          profile.role_name = RoleName.find_by_name('Teacher')
        else
          profile.role_name = RoleName.find_by_name('Student')
        end
      else
        profile.role_name = role_name
      end

      profile.save
      avatar = new_profile.avatar.dup
      avatar.profile_id = profile.id
      avatar.save
    end
    return profile
  end

  def last_action(action_type)
  return ProfileAction.where(["profile_id = ? and action_type = ?", self.id, action_type]).first
  end

  def record_action(action_type, params)
    profile_action = self.last_action(action_type)
    if profile_action.nil?
      profile_action = ProfileAction.new(:profile_id => self.id, :action_type => action_type)
    end
    profile_action.action_param = params
    profile_action.save
  end

  def delete_action
    ProfileAction.delete_all(["profile_id = ? and action_type = ?",self.id, "message"])
  end

  def major_school
    info = []
    info << self.major.name if self.major
    info << self.school.code if self.school
    return info.join(", ")
  end

  def friends
    profiles = Participant.where(["target_id = ? AND target_type = 'User' AND profile_type = 'F'", self.id])#.collect! {|x| x.profile}
    return profiles
  end

  def sports_reward
    basic = Wardrobe.where(["name = 'Basic'"]).first
    ids = [];
    if basic and !basic.nil?
      ids.push(basic.id)
    end
    sports_reward = Reward.where(["target_type = 'wardrobe' and target_id <= ?",self.wardrobe])
      .select("target_id")
    if sports_reward and !sports_reward.nil?
      sports_reward.each do |reward|
        ids.push(reward[:target_id])
      end
    end
    return ids
  end

  def has_role(type)
    Role.check_permission(self.id, type)
  end

  # Call this to make sure the user has the correct rewards for the XP gained
  def update_rewards
    level_reward = Reward.where(["xp <= ? and target_type = 'level'",  self.xp])
      .order("xp DESC")
      .first
    wardrobe_reward = Reward.where(["xp <= ? and target_type = 'wardrobe'",  self.xp], )
      .order("xp DESC")
      .first
    self.level = level_reward.target_id if level_reward
    # It is assumed that the wardrobe IDs are in ascending order of how they are unlocked. e.g. 5 is unlocked after 4
    # This is a bug, but for now we will follow this assumption until this can be fixed. This is okay as long as
    # the entire wardrobe is reloaded using the load_wardrobe.rake script.
    self.wardrobe = wardrobe_reward.target_id if wardrobe_reward
    self.save

    wardrobe = Wardrobe.find(wardrobe_reward.target_id)

    puts "Profile #{self.id} >> Level: #{self.level}, Wardrobe: #{wardrobe.name}"
  end

  def make_email_safe
    if self.email.match(/@neuronicgames.com$/)
    elsif !self.email.match(/^test-/)
      self.email = "test-#{self.email}"
      self.save
    end
  end

  def recently_messaged
    Profile.find_by_sql(
      <<-SQL
        SELECT
          profiles.*,
          MAX(messages.updated_at) AS latest_message_date,
          COUNT(message_viewers.id) AS unread_message_count
        FROM profiles
        INNER JOIN messages ON (messages.parent_id = profiles.id OR messages.profile_id = profiles.id)
        LEFT JOIN message_viewers ON (
          message_viewers.message_id = messages.id
          AND (message_viewers.poster_profile_id = profiles.id AND message_viewers.viewer_profile_id = #{self.id})
          AND (message_viewers.archived = false OR message_viewers.archived IS NULL)
          AND message_viewers.viewed = false
        ) WHERE (messages.archived = false OR messages.archived IS NULL)
          AND messages.message_type = 'Message'
          AND (
            (
              messages.target_type = 'Profile'
              AND messages.parent_type = 'Profile'
              AND (messages.parent_id = #{self.id} OR messages.profile_id = #{self.id})
            ) OR (
              messages.target_type = 'Message'
              AND messages.parent_type = 'Message'
              AND messages.parent_id IN (
                SELECT id FROM messages
                WHERE target_type = 'Profile'
                AND parent_type = 'Profile'
                AND (parent_id = #{self.id} OR profile_id = #{self.id})
                AND (archived = false OR archived IS NULL)
              )
            )
          ) AND profiles.id != #{self.id}
        GROUP BY profiles.id
        ORDER BY unread_message_count DESC, latest_message_date DESC
      SQL
    ).uniq
  end

  # Calculates the total xp that can be received for given course
  def xp_by_course(course_id)
    acc_xp = 0
    total_xp = 0
    self.task_participants.each do |tp|
      xp = tp.task.points
      acc_xp += xp if !tp.xp_award_date.nil?
      total_xp += xp
    end
    return acc_xp, total_xp
  end
  
  # Calculates the total likes that can be received for given course. Since the profile stores
  # the total likes for all courses, we need to search for course and forumn messages
  def likes_by_course(course_id)
    total_like = 0

    # Course messages
    total_like += Message.where("profile_id = ? and parent_type = ? and parent_id = ?", self.id, Course.parent_type_course, course_id).sum(:like)

    # Course forum messages
    forumn_ids = Course.select("id").where( [ "participants.profile_id = ? AND course_id = ? AND archived = ? AND removed = ?", self.id, course_id, false, false ])
      .includes([:participants])
      .joins([:participants])
    forumn_ids.each do |forumn_id|
      total_like += Message.where("profile_id = ? and parent_type = ? and parent_id = ?", self.id, Course.parent_type_forum, forumn_id).sum(:like)
    end

    return total_like
  end
  
  def xp_by_game(game_id)
    game = Game.find(game_id)
    # This assumes that feat records are ordered chronologically
    feat = game.feats.where(profile_id: self.id, progress_type: Feat.xp).last
    return feat.progress if feat
    return 0
  end
  
  def get_games(max=200)
    profile_id = self.id
    game_ids = Feat.where(profile_id: profile_id).pluck(:game_id).uniq
    # This query searches for games by ids, nad there's a limit to how many in can
    # fit into a single SQL query
    return Game.where(id: game_ids[0..max-1])
  end

  def image_url
    # If the image is from S3, the path contains the full path
    if (self.image_file_name =~ /http/) == 0  # Starts with http
      return self.image_file_name
    end

    # It's necessary to return the full URL with the domain name for external systems
    return ENV["URL"] + self.image_file_name
  end

  def self.is_profile_accessible?(profile_id, current_user_profile_id)

    profile = Profile.find(profile_id)
    return true if profile.is_public        
    
    current_user_profile = Profile.find(current_user_profile_id)
    access = false
    if current_user_profile.present? && current_user_profile.role_name_id == 1
      is_friend = false
      if current_user_profile.friends.present?
        is_friend = current_user_profile.friends.map(&:profile_id).include?(profile.id)
      end      
      if is_friend && profile.friend_privilege?
        access = true
      else
        access = false
      end    
    end
    return access 
  end

  def as_json(options = { })
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || { }).merge({
      :methods => [
        :rank
      ]
    }))
  end
  
end
