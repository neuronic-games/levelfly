class Profile < ActiveRecord::Base
  has_one :avatar
  belongs_to :major
  belongs_to :campus
  belongs_to :user
end
