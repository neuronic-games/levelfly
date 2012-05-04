class School < ActiveRecord::Base
  has_many :profile
  has_many :majors
  has_many :access_codes
  has_many :vaults, :as=>:object
  
  @@default_vault = nil
  cattr_accessor :default_vault

  def vault
    if default_vault.nil?
      default_vault = Vault.last
    end
    return default_vault
  end
end
