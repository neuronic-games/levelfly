module CourseHelper
  def show_date_format(the_date)
     return the_date.strftime('%m/%d/%Y')
  end
  def show_kilo_byte(the_byte)
     return (the_byte/1024)
  end
end
