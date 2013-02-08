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
      default_vault = Vault.last
    end
    return default_vault
  end

  def default_school?
    self.profile.map(&:code).include? "DEFAULT"
  end
end
