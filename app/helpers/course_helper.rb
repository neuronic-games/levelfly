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
  
end
