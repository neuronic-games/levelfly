class School < ActiveRecord::Base
  has_many :semesters
  has_many :profile
  has_many :majors
  has_many :access_codes
  has_many :games
  has_many :vaults, :as=>:target
  validates :handle, :uniqueness => true
  
  @@default_vault = nil
  cattr_accessor :default_vault

  @@default_date_format = 'mm/dd/yyyy'
  cattr_accessor :default_date_format

  def self.vault
    if default_vault.nil?
      default_vault = Vault.new(:vault_type => 'AWS S3', :target_id => nil, :target_type => 'School', :account => ENV['S3_KEY'], :secret => ENV['S3_SECRET'], :folder => ENV['S3_PATH'])
    end
    return default_vault
  end

  def default_school?
    self.handle == "demo"
  end
  
  def self.new_school(school_name, code, handle)
    school = School.where(["handle like ?", handle]).first
    if school.nil?
      school = School.create(:name => school_name, :code => code, :handle => handle)
      vault = Vault.create(:vault_type => 'AWS S3', :target_id => school.id, :target_type => 'School', :account => ENV['S3_KEY'], :secret => ENV['S3_SECRET'], :folder => ENV['S3_PATH'])
      profile = Profile.create(:code => 'DEFAULT', :school => school, :image_file_name => Profile.default_avatar_image, :level => 1)
      default = Avatar.create(:profile => profile, :skin => 3, :body => 'avatar/body/body_3', :head => 'avatar/head/diamond_3', :face => 'avatar/face/latin_male', :hair => 'avatar/hair/short_wavy_5', :hair_back => 'avatar/hair/short_wavy_5_back', :top => 'basic/tops/polo_short_sleeve_blue', :bottom => 'basic/bottoms/trousers_long_brown', :shoes => 'basic/shoes/sneakers_gray')
    end
    return school
  end
  
  # Create a new community admin for the school
  def self.new_admin(handle, email)
    school = School.where(["handle like ?", handle]).first
    if school
      admin_user = User.where(["email like ?", email]).first
      if admin_user.nil?
        admin_user, admin_profile = User.new_user(email, school.id, "changeme")
        admin_profile.role_name = RoleName.find_by_name('Community Admin')
        admin_profile.save
        
        return admin_user
      end
    end
    return nil
  end
  
  # Associate an existing game to the school by its handle
  def self.link_game(handle, game_handle)
    school = School.find_by_handle(handle)
    if school
      game = Game.find_by_handle(game_handle)
      if !game.nil?
        game_school = GameSchool.new
        game_school.game_id = game.id
        game_school.school_id = school.id
        game_school.save
        return game
      end
    end
    return nil
  end
  
end
