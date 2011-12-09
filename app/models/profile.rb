class Profile < ActiveRecord::Base
  has_one :avatar
  belongs_to :major
  belongs_to :school
  belongs_to :user
  has_many :participants
end
