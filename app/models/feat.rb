class Feat < ActiveRecord::Base
  belongs_to :game
  belongs_to :profile
  has_one :outcome_feat
  has_one :outcome, through: :outcome_feat

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

  @@game_level = 5
  cattr_accessor :game_level

  @@final_score = 6
  cattr_accessor :final_score

  @@duration = 7
  cattr_accessor :duration
  
  before_save :check_xp
  
  private
  
  # Make sure the constraints on xp and score are met before saving
  def check_xp
    if self.progress_type == Feat.xp
      # xp cannot be more than a 1000
      return false if self.progress > 1000
      
      # xp cannot go down
      last_xp = game.get_xp(self.profile_id)
      return false if self.progress < last_xp
    end

    return true
  end
  
end
