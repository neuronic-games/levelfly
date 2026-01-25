class Reward < ActiveRecord::Base
  def self.leveling(xp)
    Reward.where(['xp <= ?', xp])
          .order('xp DESC')
          .first
  end

  def self.notification_for_reward_sports(profile, previous_points, current_user)
    reward = Reward.where(["target_type = 'wardrobe' and target_id = '2'"]).first
    return unless reward and !reward.nil? && (previous_points < reward.xp and profile.xp >= reward.xp)

    content = 'Congratulations! You have unlocked a new wardrobe: Sports.'
    Message.send_notification(current_user, content, profile.id)
  end

  def self.notification_for_new_reward(profile, current_user)
    wardrobe = Wardrobe.find(profile.wardrobe)
    return unless wardrobe and !wardrobe.nil?

    content = "Congratulations, #{profile.full_name}! You just leveled up and unlocked a new wardrobe: #{wardrobe.name}."
    Message.send_notification(current_user, content, profile.id)
    sender = Profile.find(current_user)
    UserMailer.wardrobe_unlock_message(profile.user.email, sender, sender.school, content).deliver
  end
end
