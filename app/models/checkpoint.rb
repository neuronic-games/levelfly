class Checkpoint < ActiveRecord::Base
  belongs_to :game
  belongs_to :profile
end
