class TaskParticipant < ActiveRecord::Base
  belongs_to :task
  belongs_to :profile
  validates :task_id, :uniqueness => {:scope => :profile_id}
end
