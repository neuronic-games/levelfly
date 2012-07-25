class MessageViewer < ActiveRecord::Base
  belongs_to :message
  belongs_to :poster_profile, :class_name => "Profile"
  belongs_to :viewer_profile, :class_name => "Profile"
  
  def self.add(profile_id, message_id,parent_type,parent_id)
    object_type = nil;
    if parent_type =="C"
      object_type ="Course"
    elsif  parent_type =="G"
      object_type ="Group"
    end
    
    if (parent_type == "C" || parent_type =="G")
    @viewers = Profile.find(
       :all, 
       :include => [:participants], 
       :conditions => ["participants.object_id = ? AND participants.object_type= ? AND participants.profile_type IN ('P', 'S')", parent_id,object_type]
     )
    elsif parent_type == "Profile"
      @viewers = Profile.where("id = ?",parent_id)

    elsif  parent_type == ""
       @viewers = Profile.find(
       :all, 
       :include => [:participants],
       :conditions=>["participants.object_id = ? AND participants.object_type = 'User' AND profile_type = 'F'",profile_id])
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
      MessageViewer.create(:message_id => message_id, :poster_profile_id =>profile_id, :viewer_profile_id => profile_id) 
  end
  
  def self.remove

  end 
end
