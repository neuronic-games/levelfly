class ParticipantObserver < ActiveRecord::Observer
  
  def after_save(participant)
    unless participant.profile_type == "P"
      messages = Message.find(:all, :conditions =>["parent_id = ? and parent_type in ('C','F','G') and archived = ? ",participant.object.id, false ])
      messages.each do |message|
        message_viewer = MessageViewer.find(:first, :conditions => ["viewer_profile_id = ? and poster_profile_id = ? and message_id = ?",participant.profile_id, message.profile_id, message.id])
        unless message_viewer
          MessageViewer.create(:message_id => message.id, :poster_profile_id =>message.profile_id, :viewer_profile_id => participant.profile_id)
          comments = Message.find(:all,:conditions=>["parent_id = ? AND parent_type='Message' AND archived = ?", message.id, false])
          comments.each do |comment|
            MessageViewer.create(:message_id => comment.id, :poster_profile_id =>message.profile_id, :viewer_profile_id => participant.profile_id)
          end
        end
      end
    end
  end

end
