class RoleName < ActiveRecord::Base
  has_and_belongs_to_many :permissions
  has_many :profiles

  @@student = 1
  cattr_accessor :student

  @@teacher = 2
  cattr_accessor :teacher

  @@community_admin = 3
  cattr_accessor :community_admin

  @@levelfly_admin = 4
  cattr_accessor :levelfly_admin
end
