class Outcome < ActiveRecord::Base
  belongs_to :category
  has_and_belongs_to_many :courses
  has_many :outcome_tasks
  has_many :tasks, :through => :outcome_tasks
end
