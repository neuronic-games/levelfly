# Contains global methods for site maintenance
class Admin < ActiveRecord::Base
  
  # Remve all friends
  def self.clean_friends
    pmap = {}
    count = 0
    plist = Participant.where({:target_type => "User", :profile_type => "F"})
    plist.each do |p|
      index = "#{p.target_id},#{p.profile_id}"
      if pmap[index].nil?
        pmap[index] = p.id
      else
        Participant.delete(p.id)
        count += 1
        puts "Deleting Participant id:#{p.id} #{index}"
      end
    end
    puts "#{count} deleted"
    return count
  end
  
  # Reset all icons to the default
  def self.reset_icons
    Profile.update_all("image_file_name = '/images/wardrobe/null_profile.png'")
    Course.update_all("image_file_name = null, image_content_type = null, image_file_size = null")
    Task.update_all("image_file_name = null, image_content_type = null, image_file_size = null")
  end
  
  # Make sure all users have the correct level and wardrobe rewards
  def self.reset_rewards
    profiles = Profile.all
    profiles.each do |profile|
      next if profile.xp < 0
      profile.update_rewards
    end
  end

  # Make email addresses safe by changing them from the real one. We don't want to send out
  # emails to real users during testing.
  def self.make_email_safe
    profiles = Profile.all
    profiles.each do |profile|
      profile.make_email_safe
    end
  end
  
  # Standardize email addresses. e.g. remove spaces and make them downcase
  def self.clean_bad_emails
    users = User.all
    users.each do |user|
      email = user.email.downcase.strip
      if user.email != email
        user.update_column(:email, user.email.downcase.strip)
      end
    end
  end
end
