module CourseHelper
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
    task =  Task.find(:all, :conditions=>["course_id = ?", course_id])
    return task
  end
  
  def sort_files(id,type)
    course = Course.find(id)
    att = Attachment.find(:all, :conditions=>["object_type = ? and object_id = ?",type,id], :order=>"starred desc")
    return att
  end
  
  def already_join(group_id, profile_id)
    status = false
    profile_type = nil
    participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type = 'Group' AND profile_id = ? ", group_id, profile_id])
    if participant
      profile_type = participant.profile_type
      status = true
    end
    return status, profile_type
  end
  
end
