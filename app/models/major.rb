class Major < ActiveRecord::Base
  belongs_to :school
  has_many :profile
end
