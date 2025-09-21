module CourseHelper
  include TaskHelper
  def show_date_format(the_date)
     return the_date.strftime('%m/%d/%Y')
  end
  def show_kilo_byte(the_byte)
     return (the_byte/1024)
  end
  
  def active_task(profile_id,course_id)
    totaltask = Task.filter_by(profile_id,course_id, "current").count
    return totaltask
  end
  
  def all_task(course_id)
    task =  Task.where(["course_id = ? AND archived = ?", course_id, false])
    return task
  end
  
  def all_course(parent_type)
    courses = Course.where(["archived = ? and removed = ? and parent_type = ? and name is not null", false, false, parent_type])
    .distinct()
    .order("name")
  end
  
  def sort_files(id,type)
    course = Course.find(id)
    att = Attachment.where(["target_type = ? and target_id = ?",type,id])
    .order("starred desc")
    return att
  end
  
  def already_join(group_id, profile_id)
    status = false
    profile_type = nil
    # TODO: replace 'Course' by 'Group' 
    participant = Participant.where(["target_id = ? AND target_type = 'Course' AND profile_id = ? ", group_id, profile_id]).first
    if participant
      profile_type = participant.profile_type
      status = true
    end
    return status, profile_type
  end
  
  def member_forum(member_id, course_id)
    if member_id
      participant = Participant.where(["target_id = ? AND target_type='Course' AND profile_id = ?", course_id, member_id]).first
      if participant
        return true
      end
    else
      course = Course.find_by_id(course_id)
      forum_participants = Participant.where(["target_id = ? AND target_type='Course' AND profile_type='S'", course_id])
      course_participants = Participant.where(["target_id = ? AND target_type='Course' AND profile_type='S'", course.course_id])
      if (forum_participants.count == course_participants.count) and !course_participants.blank?
        return true
      end
    end
    return false
  end
  
end
