class Message < ActiveRecord::Base
  belongs_to :profile
  belongs_to :parent, :polymorphic=>true
  belongs_to :wall
end
