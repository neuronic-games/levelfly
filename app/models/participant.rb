class Participant < ActiveRecord::Base
  belongs_to :profile
  belongs_to :course
  belongs_to :task
end
