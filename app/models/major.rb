class Major < ActiveRecord::Base
  belongs_to :campus
  has_many :profile
end
