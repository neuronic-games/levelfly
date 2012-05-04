class Vault < ActiveRecord::Base
  belongs_to :object, :polymorphic=>true
  
  @@default_account = nil
  cattr_accessor :default_account

  @@default_secret = nil
  cattr_accessor :default_secret

  @@default_folder = nil
  cattr_accessor :default_folder
end
