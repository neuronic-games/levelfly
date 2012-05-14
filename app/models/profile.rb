class Profile < ActiveRecord::Base
  has_one :avatar
  belongs_to :major
  belongs_to :school
  belongs_to :user
  has_many :participants
  acts_as_taggable

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
end
