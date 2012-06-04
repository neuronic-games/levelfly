class TaskParticipant < ActiveRecord::Base
  belongs_to :task
  belongs_to :profile
end
