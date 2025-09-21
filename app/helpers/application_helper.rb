# Generic helper methods
module ApplicationHelper
  include MessageHelper

  # Returns true if you can access details on the specified profile
  def is_profile_accessible?(profile)
    access = true
    current_user_profile = current_user.class.name == 'User' ? current_user.profiles.first : current_user
    if current_user_profile.present? && current_user_profile.role_name_id == 1
      is_friend = false
      if current_user_profile.friends.present?
        is_friend = current_user_profile.friends.map(&:profile_id).include?(profile.id)
      end      
      if profile.is_public
        access = true
      elsif is_friend && profile.friend_privilege?
        access = true
      else
        access = false
      end    
    end
    return access 
  end

  # Are you a student?
  def student?
    current_user_profile = current_user.class.name == 'User' ? current_user.profiles.first : current_user
    return current_user_profile.role_name_id == 1
  end

  # Returns true if you have write access to the specified game
  def gamecenter_write_access(game_id)
    current_user_profile = current_user.class.name == 'User' ? current_user.profiles.first : current_user
    @game = Game.find(game_id)
    game_access = false
    if current_user_profile.role_name_id == RoleName.teacher && current_user_profile.id == @game.profile_id
      game_access = true
    elsif current_user_profile.role_name_id == RoleName.community_admin || current_user_profile.role_name_id == RoleName.levelfly_admin
      game_access = true
    end
    return game_access
  end

  # The default avatar icon for your profile
  def profile_icon_default
    return Profile.default_avatar_image
  end

  # Returns true if the email is a valid email
  def is_a_valid_email(email)
    r= Regexp.new(/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/)
  	if email.scan(r).uniq.length>0
      #if len.length>0
      return true
  	else
      return false
    end
  end

 # Convert date to application standard
 def change_date_format(date)
    if not date.blank?
      date.strftime("%m-%d-%Y")
    else
      ''
    end
  end

  # Change date/time to application standard
  def change_date_time_format(date)
    if not date.blank?
      date.strftime("%m-%d-%Y %I:%M %p")
    else
      ''
    end
  end

  # Returns true if you have unread messages
  def notification_badge(profile)
    recently_messaged = profile.recently_messaged
    return false if recently_messaged.count > 0 && recently_messaged.first.unread_message_count.to_i > 0

    recently_messaged = Message.active.involving(profile.id).where(
      :messages => {
        :message_type => 'Message',
        :target_type => 'Profile',
        :parent_type => 'Profile'
      },
      :message_viewers => {
        :viewer_profile_id => profile.id
      }
    ).joins(:message_viewers)

    profile_ids = []
    recently_messaged.map do |r|
      profile_ids.push(r.profile_id)
      profile_ids.push(r.parent_id)
    end
    profile_ids.uniq!
    profile_ids.delete(profile.id)

    messages_viewed(profile_ids, profile.id).count == 0
  end

  # Convert text content into formatted HTML, including clickable URLs
	def formatted_html_content(content)
		return auto_link(content.gsub(/\n/, '<br/>').html_safe) unless content.nil?
	end

  # Your active school
  def school
    if current_user
      session[:school_id] = current_user.default_school.id
      current_user.default_school
    elsif session[:school_id]
      School.find(session[:school_id])
    else
      School.find_by_handle("demo")
    end
  end

  # Returns your active profile that you are currently using to authenticate
  def current_profile
    Profile.find_by_user_id_and_school_id(current_user.id, school.id)
  end
end
