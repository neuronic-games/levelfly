class Campus < ActiveRecord::Base
  has_many :profile
  has_many :majors
  has_many :access_codes
end
