# Update course acc to the school id of the course

task update_course_grades: :environment do
  courses = Course.where('removed = ?', false)
  courses.each do |course|
    course_grades = CourseGrade.where(course_id: course.id)
    course_grades.each do |cg|
      cg.update_attributes(school_id: course.school_id)
    end
  end
end
