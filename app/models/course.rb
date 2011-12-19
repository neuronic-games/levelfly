class Course < ActiveRecord::Base
  belongs_to :school
  has_many :participants, :as => :object
  has_many :categories
  has_many :outcomes
end
