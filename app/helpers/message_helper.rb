module MessageHelper

  def comment_list(message_id)
    comment_ids = Message.find(:all, :select => "id" ,:conditions=>["parent_id = ? AND parent_type='Message'", message_id]).collect(&:id)
   
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ? and message_id in(?)", user_session[:profile_id],comment_ids]).collect(&:message_id)
    
    @comment = Message.find(:all, :conditions=>["id in(?)", message_ids], :order => 'created_at ASC')
    @comments = @comment.reverse.reverse
    return @comments
  end
  
  def user_like(profile_id, message_id)
    @user_like = Like.find(:first, :conditions=>["profile_id = ? AND message_id = ?", profile_id, message_id])
    if @user_like
      return true
    else 
      return false
    end
  end
  
  def is_friend(object_id, profile_id)
    @friends = Participant.find(:first, :conditions=>["object_id = ? AND profile_id = ? AND profile_type = 'F'", object_id, profile_id])
    if @friends
      return true
    else 
      return false
    end
  end
  
  def belongs_to_course_message(target_id)
    participant = Participant.where("profile_type='S' AND object_id = ? AND object_type='Course'", target_id).count
    if participant > 0
      return true
    else
      return false
    end
  end
  
  def is_course_request_pending(target_id,profile_id)
    @course_request = Participant.find(:first, :conditions=>["profile_id = ? AND object_id=? AND object_type='Course'", profile_id,target_id]) 
    return @course_request
  end
  
  def is_request_pending(parent_id, profile_id)
    @friend_request = Message.find(:first, :conditions=>["parent_id = ? AND profile_id = ? AND message_type = 'Friend' AND (archived is NULL or archived = ?)", parent_id, profile_id, false])
    if @friend_request
      return true
    else 
      return false
    end
  end
  
  def gdt(d)
    if not d.blank?
      d.strftime("%m/%d/%Y %I:%M %p")
    else
      ''
    end
  end 
  
  def last_message(profile_id,current_user)
   message = Message.find(:first, :conditions => ["(archived is NULL or archived = ?) AND message_type in ('Message') and target_type = 'Profile' and parent_type = 'Profile' and (profile_id = ? and parent_id = ?) or (profile_id = ? and parent_id = ?)",false,current_user,profile_id,profile_id,current_user],:order => "created_at DESC")
    if message
      return message.created_at
    
    end
    return nil
  end
  
end
