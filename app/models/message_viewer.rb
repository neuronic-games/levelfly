class MessageViewer < ActiveRecord::Base
  belongs_to :message
  belongs_to :poster_profile, :class_name => "Profile"
  belongs_to :viewer_profile, :class_name => "Profile"
  
  def self.add(profile_id, message_id,parent_type,parent_id)

    if parent_type=="Message"
      @type_of_message = Message.find(parent_id)
      if @type_of_message and not@type_of_message.nil?
        if (@type_of_message.parent_type == "C" || @type_of_message.parent_type == "G" || @type_of_message.parent_type == "F")
          parent_type = @type_of_message.parent_type
          parent_id =  @type_of_message.parent_id
        elsif @type_of_message.parent_type == ""    
          parent_type = @type_of_message.parent_type
        end
      end
    end
    object_type = nil;
    if parent_type =="C"
      object_type ="Course"
    elsif  parent_type =="G"
      object_type ="Group"
    end
    
    if (parent_type == "C" || parent_type =="G" || parent_type =="F")
    @viewers = Profile.find(
       :all, 
       :include => [:participants], 
       :conditions => ["participants.object_id = ? AND participants.object_type in ('Course','Group') AND participants.profile_type IN ('M', 'P', 'S')", parent_id]
     )
    elsif parent_type == "Profile"
      @viewers = Profile.where("id = ?",parent_id)
       MessageViewer.create(:message_id => message_id, :poster_profile_id =>profile_id, :viewer_profile_id => profile_id) 

    elsif  parent_type == ""
       @viewers = Profile.find(
       :all, 
       :include => [:participants],
       :conditions=>["participants.object_id = ? AND participants.object_type = 'User' AND profile_type = 'F'",profile_id])
        MessageViewer.create(:message_id => message_id, :poster_profile_id =>profile_id, :viewer_profile_id => profile_id) 
    # elsif  parent_type == "Message"
       # @viewers = Profile.find(
       # :all, 
       # :include => [:participants],
       # :conditions=>["participants.object_id = ? AND participants.object_type = 'User' AND profile_type = 'F'",profile_id])
    end
      if @viewers and not@viewers.nil?
        @viewers.each do |viewer|
          MessageViewer.create(:message_id => message_id, :poster_profile_id =>profile_id, :viewer_profile_id => viewer.id)
        end
      end
  end
  
  def self.invites(profile_id, message_id,parent_id)
     MessageViewer.create(:message_id => message_id, :poster_profile_id =>profile_id, :viewer_profile_id => parent_id) 
  end
  
  def self.remove

  end 
end
