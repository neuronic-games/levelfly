# Join model for AccessCode to School and Major
class AccessCode < ActiveRecord::Base
  belongs_to :school
  belongs_to :major
end
