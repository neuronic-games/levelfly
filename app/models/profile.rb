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
  has_many :game_score_leaders

  acts_as_taggable

  scope :course_participants, ->(course_id, section_type) {
    includes(:participants, :user).where("participants.target_id = ? AND participants.target_type IN (?) AND participants.profile_type IN ('S') AND users.status != 'D'", course_id, section_type).order(:full_name, :email)
  }
  scope :course_participants_with_master, ->(course_id, section_type) {
    includes(:participants, :user).where("participants.target_id = ? AND participants.target_type IN (?) AND participants.profile_type IN ('S','M') AND users.status != 'D'", course_id, section_type).order("users.last_sign_in_at DESC, full_name")
  }

  def self.course_master_of(course_id)
    includes(:participants).where("participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", course_id).first
  end

  def self.demo_profile
    demo = School.where(handle: 'demo').first
    Profile.find(:first, :conditions => ["code = ? and school_id = ?", 'DEFAULT', demo.id], :include => [:avatar])
  end

  def self.default_avatar_image
    return '/images/wardrobe/null_profile.png'
  end

  def self.create_for_user(user_id, school_id, default = "DEFAULT")
    profile = Profile.find(:first, :conditions => ["user_id = ? and school_id = ?", user_id, school_id])
    if profile.nil?
      new_profile = Profile.find(:first, :conditions => ["code = ? and school_id = ?", default, school_id], :include => [:avatar])

      if default == 'DEFAULT' and new_profile.nil?
        new_profile = Profile.demo_profile()
        new_profile.school_id = school_id
      end
      profile = new_profile.dup
      profile.user_id = user_id
      profile.code = nil

      demo_school = School.find_by_code('DEMO')
      if not demo_school.nil? and school_id == demo_school.id
        profile.role_name = RoleName.find_by_name('Teacher')
      else
        profile.role_name = RoleName.find_by_name('Student')
      end

      profile.save
      avatar = new_profile.avatar.dup
      avatar.profile_id = profile.id
      avatar.save
    end
    return profile
  end

  def last_action(action_type)
    return ProfileAction.find(:first, :conditions => ["profile_id = ? and action_type = ?", self.id, action_type])
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
    profiles = Participant.find(:all, :conditions=>["target_id = ? AND target_type = 'User' AND profile_type = 'F'", self.id])#.collect! {|x| x.profile}
    return profiles
  end

  def sports_reward
    basic = Wardrobe.find(:first, :conditions=>["name = 'Basic'"])
    ids = [];
    if basic and !basic.nil?
      ids.push(basic.id)
    end
    sports_reward = Reward.find(:all, :select => "target_id", :conditions=>["target_type = 'wardrobe' and target_id <= ?",self.wardrobe])
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
    level_reward = Reward.find(:first, :conditions => ["xp <= ? and target_type = 'level'",  self.xp], :order => "xp DESC")
    wardrobe_reward = Reward.find(:first, :conditions => ["xp <= ? and target_type = 'wardrobe'",  self.xp], :order => "xp DESC")
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

end
