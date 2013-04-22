# Remove Old messages that should have been deleted due to #306

task :remove_old_deleted_messages => :environment do
  courses = Course.where("removed = ?",false)
  courses.each do |course|
    course_partcipants = course.participants
    course_partcipants.each do |participant|
      participant_message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", participant.profile_id]).collect(&:message_id)

      owner_message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", course.owner.id]).collect(&:message_id)

      participant_course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = ? and id in(?)", course.id, course.parent_type, participant_message_ids]).collect(&:id)

      owner_course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = ? and id in(?)", course.id, course.parent_type, owner_message_ids]).collect(&:id)

      delete_messages = participant_course_messages - owner_course_messages

      owner_course_messages.each do|message|
        comment_ids = Message.find(:all, :select => "id" ,:conditions=>["parent_id = ? AND parent_type='Message'", message]).collect(&:id)

        owner_comment_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ? and message_id in(?)", course.owner.id,comment_ids]).collect(&:message_id)

        participant_comment_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ? and message_id in(?)", participant.profile_id,comment_ids]).collect(&:message_id)

        delete_messages.concat(participant_comment_ids - owner_comment_ids)
      end

      count = MessageViewer.delete_all(["viewer_profile_id = ? and message_id in (?)", participant.profile_id,delete_messages])
      
      puts "#{count} messages deleted"
    end
  end

end