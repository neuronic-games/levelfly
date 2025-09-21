class ParticipantObserver < ActiveRecord::Observer
  def after_save(participant)
    if participant.profile_type == 'S'
      message_ids = MessageViewer.where(['viewer_profile_id = ?', participant.target.owner.id])
                                 .select('message_id')
                                 .collect(&:message_id)
      messages = Message.where(["parent_id = ? and parent_type in ('C','F','G') and archived = ? and id in (?)",
                                participant.target.id, false, message_ids])
      messages.each do |message|
        message_viewer = MessageViewer.where(['viewer_profile_id = ? and poster_profile_id = ? and message_id = ?',
                                              participant.profile_id, message.profile_id, message.id]).first
        next if message_viewer

        MessageViewer.create(message_id: message.id, poster_profile_id: message.profile_id,
                             viewer_profile_id: participant.profile_id)
        comments = Message.where(["parent_id = ? AND parent_type='Message' AND archived = ?", message.id, false])
        comments.each do |comment|
          MessageViewer.create(message_id: comment.id, poster_profile_id: message.profile_id,
                               viewer_profile_id: participant.profile_id)
        end
      end
    end
  end
end
