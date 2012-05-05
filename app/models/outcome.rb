class Outcome < ActiveRecord::Base
  has_many :outcome_tasks
  belongs_to :category
  has_and_belongs_to_many :courses
end
