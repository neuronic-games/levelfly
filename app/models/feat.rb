class Feet < ActiveRecord::Base
  belongs_to :game
  belongs_to :profile

  @@login = 0
  cattr_accessor :login

  @@xp = 1
  cattr_accessor :xp

  @@score = 2
  cattr_accessor :score

  @@badge = 3
  cattr_accessor :badge

  @@rating = 4
  cattr_accessor :rating
  
  before_save :check_xp
  
  private
  
  def check_xp
    # xp cannot be more than a 1000
    if self.xp > 1000
      self.xp = 1000
    end
  end
  
end
