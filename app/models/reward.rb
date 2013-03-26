class Reward < ActiveRecord::Base

  def self.leveling(xp)
    level = Reward.find(:first, :conditions=>["xp <= ?", xp], :order=>"xp DESC")   
    return level
  end
  
  def self.notification_for_reward_sports(profile,previous_points,current_user)
    reward = Reward.find(:first, :conditions=>["object_type = 'wardrobe' and object_id = '2'"])
    if reward and !reward.nil?
     if previous_points < reward.xp and profile.xp >= reward.xp
       content = "Congratulations! You have unlocked a new wardrobe: Sports."
       Message.send_notification(current_user,content,profile.id)
     end
    end
  end

  def self.notification_for_new_reward(profile,current_user)
    wardrobe = Wardrobe.find(profile.wardrobe)
    if wardrobe and !wardrobe.nil?
      content = "Congratulations! You have unlocked a new wardrobe: #{wardrobe.name}."
      Message.send_notification(current_user,content,profile.id)
      sender = Profile.find(current_user)
      UserMailer.wardrobe_unlock_message(profile.user.email,sender,sender.school,content).deliver
    end
    
  end

end
