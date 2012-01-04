class School < ActiveRecord::Base
  has_many :profile
  has_many :majors
  has_many :access_codes
  has_many :vaults, :as=>:object
end
