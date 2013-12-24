class Profile < ActiveRecord::Base
  has_one :avatar
  belongs_to :major
  belongs_to :school
  belongs_to :user
  has_many :participants
	has_many :task_participants
  has_many :profile_actions
  acts_as_taggable

  def self.default_avatar_image
    return '/images/wardrobe/null_profile.png'
  end
  
  def self.create_for_user(user_id, school_id, default = "DEFAULT")
    profile = Profile.find(:first, :conditions => ["user_id = ?", user_id])
    if profile.nil?
      new_profile = Profile.find(:first, :conditions => ["code = ? and school_id = ?", default, school_id], :include => [:avatar])

      profile = new_profile.dup
      profile.user_id = user_id
      profile.code = nil
      profile.save
      avatar = new_profile.avatar.dup
      avatar.profile_id = profile.id
      avatar.save
      Role.set_user_role(profile.id)
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
    profiles = Participant.find(:all, :conditions=>["object_id = ? AND object_type = 'User' AND profile_type = 'F'", self.id])#.collect! {|x| x.profile}
    return profiles
  end
  
  def sports_reward
    basic = Wardrobe.find(:first, :conditions=>["name = 'Basic'"])
    ids = [];
    if basic and !basic.nil?
      ids.push(basic.id)
    end
    sports_reward = Reward.find(:all, :select => "object_id", :conditions=>["object_type = 'wardrobe' and object_id <= ?",self.wardrobe])
    if sports_reward and !sports_reward.nil?
      sports_reward.each do |reward|
        ids.push(reward[:object_id])
      end
    end
    return ids
  end

  def has_role(type)
    Role.check_permission(self.id, type)
  end
  
end
