class Permission < ActiveRecord::Base
  has_and_belongs_to_many :role_names

  def self.names
    select('name').map(&:name)
  end
end
