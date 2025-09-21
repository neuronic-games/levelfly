class Like < ActiveRecord::Base
  belongs_to :message
  belongs_to :profile

  after_create :push_like
  before_destroy :push_like

  def push_like
    total_likes = message.like

    if course_id.blank?
      # if like belongs to message boards
      recievers = Profile.find(profile_id).friends.map(&:profile_id) - [profile_id]
    else
      # if like belongs_to course
      course_master_id = Course.find(course_id).owner.id
      recievers = Profile.course_participants(course_id, 'Course').map(&:id) + [course_master_id] - [profile_id]
    end

    recievers.each do |receiver_id|
      pusher_content = { message_id: message_id, total_likes: total_likes, event: 'message_likes' }
      Pusher.trigger_async("private-my-channel-#{receiver_id}", 'message', pusher_content)
    end
  end

  def self.add(message_id, profile_id, course_id)
    # Update the like count for the message
    message = Message.find(message_id)
    message.like += 1
    message.save

    # Record who liked the message
    like = Like.create(message_id: message_id, profile_id: profile_id, course_id: course_id)

    # Update the like count for the giver
    profile = Profile.find(profile_id)
    profile.like_given += 1
    profile.save

    # Update the like count for the recipient
    profile = Profile.find(message.profile_id)
    profile.like_received += 1
    profile.save

    message
  end

  def self.remove(message_id, profile_id, _course_id)
    message = nil
    like = Like.where(['message_id = ? and profile_id = ?', message_id, profile_id]).first
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
    message
  end
end
