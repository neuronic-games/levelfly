class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # SELECT `participants`.* FROM `participants` WHERE (object_id = 7 AND object_type = 'User' AND profile_type = 'F')
  # has_many :friends, :as => :participant, :conditions => ['profile_type = ?', 'F']
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  
  def friends
    profiles = Participant.find(:all, :conditions=>["object_id = ? AND object_type = 'User' AND profile_type = 'F'", self.id]).collect! {|x| x.profile}
    return profiles
  end
  
  def add_friend(profile_id)
    profile_ids = Participant.find(:all, :conditions=>["object_id = ? AND object_type = 'User' AND profile_id = ? AND profile_type = 'F'", self.id, profile_id]).collect! {|x| x.profile_id}
    if !profile_ids.include?(profile_id)
      Participant.create(:object_id => self.id, :object_type => 'User', :profile_id => profile_id, :profile_type => 'F')
    end
  end
  
end
