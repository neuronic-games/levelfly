class OutcomeTask < ActiveRecord::Base
  belongs_to :outcome
  belongs_to :task
end
