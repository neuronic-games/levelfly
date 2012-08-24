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
  
end
