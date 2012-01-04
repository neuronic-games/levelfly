class Vault < ActiveRecord::Base
  belongs_to :object, :polymorphic=>true
end
