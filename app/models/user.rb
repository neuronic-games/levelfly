class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable#, :Confirmable

  # SELECT `participants`.* FROM `participants` WHERE (target_id = 7 AND target_type = 'User' AND profile_type = 'F')
  # has_many :friends, :as => :participant, :conditions => ['profile_type = ?', 'F']
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :remember_me
 
  has_many :profiles

  @@status_active = 'A'
  cattr_accessor :status_active

  @@status_deleted = 'D'
  cattr_accessor :status_deleted

  @@status_suspended = 'S'
  cattr_accessor :status_suspended

  before_create :lower_email
  before_save :lower_email

  def lower_email
    self.email = self.email.downcase.strip
  end

  def default_school
    @_default_school ||= School.find_by_id(self.default_school_id) || self.profiles.first.school
  end

  def default_school=(school)
    self.default_school_id = school.id
    @_default_school = school
  end

  def friends
    profiles = Participant.find(:all, :conditions=>["target_id = ? AND target_type = 'User' AND profile_type = 'F'", self.id]).collect! {|x| x.profile}
    return profiles
  end
  
  def add_friend(profile_id)
    profile_ids = Participant.find(:all, :conditions=>["target_id = ? AND target_type = 'User' AND profile_id = ? AND profile_type = 'F'", self.id, profile_id]).collect! {|x| x.profile_id}
    if !profile_ids.include?(profile_id)
      Participant.create(:target_id => self.id, :target_type => 'User', :profile_id => profile_id, :profile_type => 'F')
    end
  end

  def regenerate_confirmation_token
    self.generate_confirmation_token
  end
  
  def self.new_user(email, school_id, password = nil)
    if @user = find_by_email(email)
      
    else
      @user = User.new do |u|
        u.email = email
        u.password = password ? password : "defaultpassword"
        #u.reset_password_token= User.reset_password_token 
      end
      @user.skip_confirmation!
      @user.save(:validate => false)

      @user.confirmed_at = nil
      @user.confirmation_sent_at = Time.now
      @user.save(:validate => false)
    end
    
    if @user
      @profile = Profile.create_for_user(@user.id,school_id)
    end
    return @user, @profile
    
  end
  
  def full_name
  end

  def self.find_by_email_and_school_id(email, school_id)
    User.joins(:profiles).find(:first, :conditions => ["users.email = ? AND profiles.school_id = ?", email, school_id])
  end
  
  # Delete User who is not register their acoount yet.
  def self.delete_pending_user(profile_id)
    profile = Profile.find(profile_id)
    if profile
      user = User.find(profile.user_id)
      if user and user.sign_in_count == 0
        user.delete
        profile.delete
      end
    end
  end
  
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    conditions[:email].downcase! if conditions[:email]
    where(conditions).where("email !~* '^del-'").first
  end
  
end
