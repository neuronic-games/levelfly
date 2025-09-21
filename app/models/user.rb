class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # SELECT `participants`.* FROM `participants` WHERE (target_id = 7 AND target_type = 'User' AND profile_type = 'F')
  # has_many :friends, :as => :participant, :conditions => ['profile_type = ?', 'F']

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :remember_me

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

  def default_profile
    return self.profiles.first if self.default_school_id.nil?
  return Profile.where({:school_id => self.default_school_id, :user_id => self.id}).first
  end
  
  def default_school=(school)
    self.default_school_id = school.id
    @_default_school = school
  end

  def friends
    profiles = Participant.where(["target_id = ? AND target_type = 'User' AND profile_type = 'F'", self.id]).collect! {|x| x.profile}
    return profiles
  end

  def add_friend(profile_id)
    profile_ids = Participant.where(["target_id = ? AND target_type = 'User' AND profile_id = ? AND profile_type = 'F'", self.id, profile_id]).collect! {|x| x.profile_id}
    if !profile_ids.include?(profile_id)
      Participant.create(:target_id => self.id, :target_type => 'User', :profile_id => profile_id, :profile_type => 'F')
    end
  end

  def regenerate_confirmation_token
    self.generate_confirmation_token
  end

  def self.new_user(email, school_id, password = nil, send_email = false, role_name = nil)
    if @user = find_by_email(email)

    else
      @user = User.new do |u|
        u.email = email
        u.password = password ? password : "defaultpassword"
        # u.reset_password_token= User.reset_password_token
      end

      if !send_email 
        @user.skip_confirmation!
      end

      @user.save(:validate => false)

      # @user.confirmed_at = nil
      # @user.confirmation_sent_at = Time.now
      # @user.save(:validate => false)
    end

    ### Temp fix to allow only 1 profile for 1 user
    if @user && @user.profiles.count > 0
      @profile = nil
    elsif @user
      # Create a new profile using the DEFAULT template for the school
      @profile = Profile.create_for_user(@user.id, school_id, "DEFAULT", role_name)
    end
    ### Code before temp fix:
    # if @user
    #   @profile = Profile.create_for_user(@user.id,school_id)
    # end
    return @user, @profile

  end

  def full_name
  end

  def self.find_by_email_and_school_id(email, school_id)
    User.joins(:profiles).where(["users.email = ? AND profiles.school_id = ?", email, school_id]).first
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

  def self.to_csv(profiles)    
    CSV.generate do |csv|
      csv << ['id', 'full_name', 'email', 'created_at', 'last_sign_in_at', 'xp', 'level', 'school_name', 'school_nandle']
      profiles.each do |p|
        arr = [
            p.id,
            p.full_name,
            p.user.email,
            p.created_at,
            p.user.last_sign_in_at,
            p.xp,
            p.level,
            p.school.name,
            p.school.handle
        ]
        csv << arr
      end
    end
  end

  def self.to_emails(id, profile_id)
    profiles = User.find_with_filters(id, profile_id)

    if id == 'all_active'
      demo_profiles = User.find_demo_users
      profiles += demo_profiles if demo_profiles
    end

    profiles.map {|p| p.user.email}
  end

  def self.find_demo_users
    demo_school = School.find_by_handle("demo")
    if demo_school
      demo_profiles = Profile.includes(:user)
        .where("school_id = ? and user_id is not null and users.status != 'D'", demo_school.id)
        .order("last_sign_in_at DESC NULLS LAST, full_name")
    else
      nil
    end
  end

  def self.find_by_like_email(email)
    at = User.arel_table
    return User.where(at[:email].matches(email)).first
  end
  
  class << self

    def find_with_filters(id, profile_id,params, page = -1)
      puts "PageNo: #{page}"
      @profile = Profile.find(profile_id)
      school_id = @profile.school_id
      demo_school_id = School.find_by_handle("demo").id
      profile_ids = []
      @users = []
      if id == "all_active"
        if page > -1
          @users = Profile.includes(:user)
            .where("school_id IN (?) and user_id is not null and users.status != 'D'", [school_id, demo_school_id])
            .order("last_sign_in_at DESC NULLS LAST, full_name").paginate(:page => page, :per_page => Setting.cut_off_number)
            .joins(:user)
        else
          @users = Profile.includes(:user)
            .where("school_id IN (?) and user_id is not null and users.status != 'D'", [school_id, demo_school_id])
            .order("last_sign_in_at DESC NULLS LAST, full_name")
            .joins(:user)
        end
      elsif id == "members_of_courses"
        course_ids = Course.where(["archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?", false, false, "C", school_id]).collect(&:id)
        .distinct
        .order("name")
        profile_ids = Participant.where(["target_id IN (?)",course_ids]).collect(&:profile_id).distinct
      elsif id == "members_of_groups"
        course_ids = Course.where(["archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?", false, false, "G", school_id])
          .distinct
          .order("name")
          .collect(&:id)
        profile_ids = Participant.where(["target_id IN (?)",course_ids]).collect(&:profile_id).distinct
      elsif id == "organizers_of_courses"
        course_ids = Course.where(["archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?", false, false, "C", school_id])
          .order("name")
          .collect(&:id)
        profile_ids = Participant.where(["target_id IN (?) AND profile_type = 'M'", course_ids]).collect(&:profile_id).distinct
      elsif id == "organizers_of_groups"
        course_ids = Course.where(["archived = ? and removed = ? and parent_type = ? and name is not null and school_id = ?", false, false, "G", school_id])
          .order("name")
          .collect(&:id)
        profile_ids = Participant.where(["target_id IN (?) AND profile_type = 'M'", course_ids]).collect(&:profile_id).distinct
      elsif id == "organizers_of_courses_and_groups"
        course_ids = Course.where(["archived = ? and removed = ? and name is not null and school_id = ?", false, false, school_id])
          .order("name")
          .collect(&:id)
        profile_ids = Participant.where(["target_id IN (?) AND profile_type = 'M'", course_ids]).collect(&:profile_id).distinct
      else
        course_ids = []
        if params[:id].split('_').count > 1          
          params[:year_range] = params[:id].split('_').first
          params[:course_code] = params[:id].split('_').last
          params[:school_id] = school_id
          @courses = Course.get_courses_by_year_range(params)
          course_ids = @courses.map(&:id) if @courses.present?
        else          
          course_ids = Course.where(id: id).collect(&:id)
        end
        profile_ids = Participant.where(target_type: "Course").where(target_id: course_ids).pluck(:profile_id).uniq
      end
          
      if id != "all_active" && profile_ids.present?
        if page > -1
          @users = Profile
            .includes(:participants, :user)
            .where(id: profile_ids)
            .where("participants.profile_type IN ('S','M') AND users.status != 'D'")
            .order("users.last_sign_in_at DESC, full_name")
            .paginate(:page => page, :per_page => Setting.cut_off_number)
            .joins(:user, :participants)
        else          
          @users = Profile.includes(:participants, :user).where(id: profile_ids)
            .where("participants.profile_type IN ('S','M') AND users.status != 'D'")
            .order("users.last_sign_in_at DESC, full_name")
            .joins(:user, :participants)
        end    
      end
      @profile.record_action('last', 'users')
      @users
    end
  end

end
