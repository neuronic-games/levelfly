module ApplicationHelper
 
 def is_a_valid_email(email)
  
  r= Regexp.new(/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/)
	if email.scan(r).uniq.length>0
    #if len.length>0
    return true 
	else
    return false
  end
 end
  
 def change_date_format(date)
    if not date.blank?
      date.strftime("%m-%d-%Y")
    else
      ''
    end
  end 
  
  def notification_badge(profile)
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?", profile.id]).collect(&:wall_id)
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", profile.id]).collect(&:message_id)
    recently_messaged = Message.find(:all, :conditions => ["(archived is NULL or archived = ?) AND message_type in ('Message') and id in (?) and target_type = 'Profile' and parent_type = 'Profile' and (profile_id = ? or parent_id = ?)",false,message_ids,profile.id,profile.id],:order=>"created_at desc")
    profile_ids = []
    users = []
    recently_messaged.each do |r|
      profile_ids.push(r.profile_id)
      profile_ids.push(r.parent_id)
    end
    profile_ids=profile_ids.uniq
    if profile_ids.length>0
        profile_ids.each do |id|
          if id != profile.id
            user = Profile.find(id)
            users.push(user)
          end  
        end
    end
    users.each do |user|
      message = Message.find(:first, :conditions => ["(archived is NULL or archived = ?) AND message_type in ('Message') and target_type = 'Profile' and parent_type = 'Profile' and profile_id = ? and parent_id = ?",false,user.id,profile.id],:order => "created_at DESC")
      if message
        message_viewer =MessageViewer.find(:first, :conditions => ["(archived is NULL or archived = ?) AND message_id = ? AND poster_profile_id = ? AND viewer_profile_id = ?",false,message.id,user.id,profile.id], :order => "created_at DESC")
        if message_viewer
          if !message_viewer.viewed
            return message_viewer.viewed
          end
        end
      end
    end
    return true
  end
	
	def formatted_html_content(content)
		return auto_link(content.gsub(/\n/, '<br/>').html_safe) unless content.nil?
	end
  
  def school
    School.find(session[:school_id])
  end
  
end
