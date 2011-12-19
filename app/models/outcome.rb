class Outcome < ActiveRecord::Base
  has_many :outcome_tasks
  belongs_to :category
end
