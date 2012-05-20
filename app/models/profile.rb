class Profile < ActiveRecord::Base
  has_one :avatar
  belongs_to :major
  belongs_to :school
  belongs_to :user
  has_many :participants
  has_many :profile_actions
  acts_as_taggable

  def self.default_avatar_image
    return '/images/wardrobe/null_profile.png'
  end
  
  def self.create_for_user(user_id, default = "DEFAULT")
    profile = Profile.find(:first, :conditions => ["user_id = ?", user_id])
    if profile.nil?
      new_profile = Profile.find_by_code(default, :include => [:avatar])

      profile = new_profile.dup
      profile.user_id = user_id
      profile.code = nil
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
end
