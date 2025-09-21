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
        elsif @type_of_message.parent_type == "Profile"
          @viewers = Profile.where(["id in (?)",[@type_of_message.profile_id,@type_of_message.parent_id]])
        end
      end
    end
    target_type = nil;
    if parent_type =="C"
      target_type ="Course"
    elsif  parent_type =="G"
      target_type ="Group"
    end
    
    if (parent_type == "C" || parent_type =="G" || parent_type =="F")
    @viewers = Profile.where( ["participants.target_id = ? AND participants.target_type in ('Course','Group') AND participants.profile_type IN ('M', 'P', 'S')", parent_id])
       .include([:participants])
       .joins([:participants])
    elsif parent_type == "Profile"
      @viewers = Profile.where("id = ?",parent_id)
       MessageViewer.create(:message_id => message_id, :poster_profile_id =>profile_id, :viewer_profile_id => profile_id) 

    elsif  parent_type == ""
       @viewers = Profile.where( [ "participants.target_id = ? AND participants.target_type = 'User' AND profile_type = 'F'", profile_id ])
         .include([:participants])
         .joins([:participants])
       MessageViewer.create(:message_id => message_id, :poster_profile_id =>profile_id, :viewer_profile_id => profile_id) 
    # elsif  parent_type == "Message"
       # @viewers = Profile.find(
       # :all, 
       # :include => [:participants],
       # :conditions=>["participants.target_id = ? AND participants.target_type = 'User' AND profile_type = 'F'",profile_id])
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
