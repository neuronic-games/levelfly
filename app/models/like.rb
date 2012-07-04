class Like < ActiveRecord::Base
  belongs_to :message
  belongs_to :profile
  
  def self.add(message_id, profile_id,course_id)
    # Update the like count for the message
    message = Message.find(message_id)
    message.like += 1
    message.save
    
    # Record who liked the message
    like = Like.create(:message_id => message_id, :profile_id => profile_id, :course_id=> course_id)

    # Update the like count for the giver
    profile = Profile.find(profile_id)
    profile.like_given += 1
    profile.save
    
    # Update the like count for the recipient
    profile = Profile.find(message.profile_id)
    profile.like_received += 1
    profile.save

    return message
  end

  def self.remove(message_id, profile_id,course_id)
    message = nil
    like = Like.find(:first, :conditions => ["message_id = ? and profile_id = ?", message_id, profile_id])
    if like
      # Update the like count for the message
      message = Message.find(message_id)
      message.like -= 1
      message.save
      
      # Remove the like
      like.destroy
      
      # Update the like count for the giver
      profile = Profile.find(profile_id)
      profile.like_given -= 1
      profile.save

      # Update the like count for the recipient
      profile = Profile.find(message.profile_id)
      profile.like_received -= 1
      profile.save
    end
    return message
  end
end
