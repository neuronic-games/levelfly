class Game < ActiveRecord::Base
  validates :handle, :uniqueness => true
end
