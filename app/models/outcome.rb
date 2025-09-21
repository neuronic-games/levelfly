class Outcome < ActiveRecord::Base
  belongs_to :category
  has_and_belongs_to_many :courses
  has_many :outcome_tasks, dependent: :destroy
  has_many :tasks, through: :outcome_tasks
  has_many :feats, through: :outcome_feats
  belongs_to :game
end
