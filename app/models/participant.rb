class Participant < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :profile
end
