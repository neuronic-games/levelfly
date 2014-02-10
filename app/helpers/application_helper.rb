module ApplicationHelper
 include MessageHelper
 
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
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", profile.id]).collect(&:message_id)
    recently_messaged = Message.active.involving(profile).find(
      :all, 
      :joins => :message_viewers,
      :conditions => {
        :messages => {
          :message_type => 'Message',
          :target_type => 'Profile',
          :parent_type => 'Profile'
        },
        :message_viewers => {
          :viewer_profile_id => profile.id
        }
      }
    )

    profile_ids = []
    recently_messaged.map do |r|
      profile_ids.push(r.profile_id)
      profile_ids.push(r.parent_id)
    end
    profile_ids.uniq!
    profile_ids.delete(profile.id)

    messages_viewed(profile_ids, profile.id)
  end
	
	def formatted_html_content(content)
		return auto_link(content.gsub(/\n/, '<br/>').html_safe) unless content.nil?
	end
  
  def school
    current_school = School.find(session[:school_id]) if session[:school_id]
    current_school = School.find_by_handle("bmcc") unless session[:school_id]
    return current_school
  end
  
end
