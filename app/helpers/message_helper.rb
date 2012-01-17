module MessageHelper

  def comment_list(message_id)
    @comments = Message.find(:all, :conditions=>["parent_id = ? AND parent_type='Message'", message_id])
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
  
end
