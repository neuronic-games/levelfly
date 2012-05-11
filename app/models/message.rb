class Message < ActiveRecord::Base
  belongs_to :profile
  belongs_to :parent, :polymorphic=>true
  belongs_to :wall
  
  def self.send_friend_request(profile_id,parent_id,wall_id)
    @message = Message.new
    @message.profile_id = profile_id
    @message.parent_id = parent_id
    @message.parent_type = "Course"
    @message.message_type = "Friend"
    @message.content = "Friend Request!!!"
    @message.wall_id = Wall.get_wall_id(parent_id, "Course") 
    @message.post_date = DateTime.now
    @message.save
    return @message
  end
end
