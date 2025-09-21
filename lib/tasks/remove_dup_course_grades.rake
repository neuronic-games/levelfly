# Remove duplicate course grades that were created during Gradebook Performance Issue

task :remove_dup_course_grades => :environment do
  courses = Course.where("removed = ?",false)
  count = 0
  courses.each do |course|
    course_participants = course.participants
    course_participants.each do |cp|
      cg = CourseGrade.where(["course_id = ? and profile_id = ? and outcome_id is null",course.id,cp.profile_id])
        .order("created_at ASC")
        .first
      deleted = CourseGrade.delete_all(["course_id = ? and profile_id = ? and outcome_id is null and id not in (?)",course.id,cp.profile_id,cg]) if cg
      count += deleted if deleted
    end
  end
  
  puts "#{count} duplicates removed"
  
  # update gradebook
  
  tasks = Task.where("archived = ?",false)
  tasks.each do |task|
    task.grade_recalculate
  end
  
end
