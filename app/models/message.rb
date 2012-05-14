class Message < ActiveRecord::Base
  belongs_to :profile
  belongs_to :parent, :polymorphic=>true
  belongs_to :wall
  
  def self.send_friend_request(profile_id,parent_id,wall_id,target_id)
    @message = Message.new
    @message.profile_id = profile_id
    @message.parent_id = parent_id
    @message.target_id = target_id
    @message.target_type = "Course"
    @message.parent_type = "Course"
    @message.message_type = "course_invite"
    @message.content = "Friend Request!!!"
    @message.wall_id = Wall.get_wall_id(parent_id, "Course") 
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    return @message
  end
end
