module MessageHelper

  def comment_list(message_id)
    @comment = Message.find(:all, :conditions=>["parent_id = ? AND parent_type='Message'", message_id], :order => 'created_at ASC')
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
  
end
