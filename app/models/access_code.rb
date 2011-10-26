class AccessCode < ActiveRecord::Base
  belongs_to :school
  belongs_to :major
end
