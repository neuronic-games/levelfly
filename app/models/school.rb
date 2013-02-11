class School < ActiveRecord::Base
  has_many :profile
  has_many :majors
  has_many :access_codes
  has_many :vaults, :as=>:object
  validates :handle, :uniqueness => true
  
  @@default_vault = nil
  cattr_accessor :default_vault

  @@default_date_format = 'mm/dd/yyyy'
  cattr_accessor :default_date_format

  def self.vault
    if default_vault.nil?
      default_vault = Vault.new(:vault_type => 'AWS S3', :object_id => nil, :object_type => 'School', :account => ENV['S3_KEY'], :secret => ENV['S3_SECRET'], :folder => ENV['S3_PATH'])
    end
    return default_vault
  end

  def default_school?
    self.handle == "bmcc"
  end
  
  def self.new_school(school_name, code, handle)
    school = School.create(:name => school_name, :code => code, :handle => handle)
    vault = Vault.create(:vault_type => 'AWS S3', :object_id => school.id, :object_type => 'School', :account => ENV['S3_KEY'], :secret => ENV['S3_SECRET'], :folder => ENV['S3_PATH'])
    profile = Profile.create(:code => 'DEFAULT', :school => school, :image_file_name => Profile.default_avatar_image, :level => 1)
    default = Avatar.create(:profile => profile, :skin => 3, :body => 'avatar/body/body_3', :head => 'avatar/head/diamond_3', :face => 'avatar/face/latin_male', :hair => 'avatar/hair/short_wavy_5', :hair_back => 'avatar/hair/short_wavy_5_back', :top => 'basic/tops/polo_short_sleeve_blue', :bottom => 'basic/bottoms/trousers_long_brown', :shoes => 'basic/shoes/sneakers_gray')
    return school
  end
  
end
