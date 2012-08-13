class Reward < ActiveRecord::Base

  def self.leveling(xp)
    level = Reward.find(:first, :conditions=>["xp <= ?", xp], :order=>"xp DESC")   
    return level
  end
end
