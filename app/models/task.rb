class Task < ActiveRecord::Base
  belongs_to :category
  belongs_to :school
  belongs_to :task
  has_many :participants, :as => :object
  has_many :outcome_tasks
end
