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
    @message.content = "I'd like to be your friend. Please accept my invite."
    @message.wall_id = Wall.get_wall_id(parent_id, "Course") 
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    return @message
  end

  def self.send_course_request(profile_id, parent_id, wall_id, target_id,section_type)
    course = Course.find(target_id)
    @message = Message.new
    @message.profile_id = profile_id 
    @message.parent_id = parent_id
    @message.target_id = target_id
    @message.target_type = section_type
    @message.parent_type = section_type
    @message.message_type = "course_invite"
    @message.content = "Please join #{course.name} (#{course.code_section})"
    @message.wall_id = wall_id#Wall.get_wall_id(parent_id, "Course") 
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    MessageViewer.invites(profile_id, @message.id,parent_id)
    return @message
  end
  
  def self.respond_to_course_invitation(parent_id,profile_id,target_id,content,section_type)
    course = Course.find(target_id)
    @message = Message.new
    @message.profile_id = parent_id
    @message.parent_id = profile_id
    @message.target_id = target_id
    # Needs the wall id for the recipient
    @message.target_type = section_type
    @message.parent_type = "Profile"
    @message.message_type = "Message"
    @message.content = content+" your invite"
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    MessageViewer.invites(parent_id, @message.id,profile_id)
    return @message
  end
  
  def formatted_content
    lines = self.content.split("\n")
    lines[0] = "<span class='subject'>#{lines[0]}</span>" if lines.length > 1
    final = lines.join("<br />")
    return final.html_safe
  end
  
  def self.change_level(parent_id,level,profile_id)
    @message = Message.new
    @message.profile_id = parent_id
    @message.parent_id = profile_id
    @message.target_type = "Notification"
    @message.parent_type = "Profile"
    @message.message_type = "Message"
    @message.content = "Congrtulation! You are move to level #{level}"
    @message.archived = false
    @message.post_date = DateTime.now
    @message.save
    MessageViewer.invites(parent_id, @message.id,profile_id)
  
  end
end
