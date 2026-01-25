class Vault < ActiveRecord::Base
  belongs_to :target, polymorphic: true
end
