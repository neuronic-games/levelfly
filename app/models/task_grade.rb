class TaskGrade < ActiveRecord::Base

  def self.task_grades(school_id,course_id,task_id, profile_id,task_grade)
    @grade= TaskGrade.where("school_id = ? and course_id = ? and task_id =? and profile_id = ? ",school_id,course_id,task_id,profile_id).first
    if !@grade.nil?
      self.task_grade_update(school_id,course_id,task_id, profile_id,task_grade,@grade)
    else
      self.task_grade_save(school_id,course_id,task_id, profile_id,task_grade)
    end
  end

  def self.task_grade_save(school_id,course_id,task_id, profile_id,task_grade)
    grade = GradeType.letter_to_value(task_grade, school_id)
    @task_grade = TaskGrade.new
    @task_grade.school_id = school_id
    @task_grade.course_id = course_id
    @task_grade.task_id = task_id
    @task_grade.profile_id = profile_id
    @task_grade.grade = grade
    @task_grade.save
   
  end
  
  def self.task_grade_update(school_id,course_id,task_id, profile_id,task_grade,grade_obj)
    grade = GradeType.letter_to_value(task_grade, school_id)
    grade_obj.update_attribute('grade',grade)
   
  end

end
