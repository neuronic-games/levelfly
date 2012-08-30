class TaskGrade < ActiveRecord::Base
  belongs_to :task
  
  def self.task_grades(school_id,course_id,task_id, profile_id,task_grade,grade)
    @grade= TaskGrade.where("school_id = ? and course_id = ? and task_id =? and profile_id = ? ",school_id,course_id,task_id,profile_id).first
    CourseGrade.save_grade(profile_id, grade, course_id)
    if !@grade.nil?
      self.task_grade_update(task_grade,@grade)
    else
      self.task_grade_save(school_id,course_id,task_id, profile_id,task_grade)
    end
  end

  def self.task_grade_save(school_id,course_id,task_id, profile_id,task_grade)
    #grade = GradeType.letter_to_value(task_grade, school_id)
    @task_grade = TaskGrade.new
    @task_grade.school_id = school_id
    @task_grade.course_id = course_id
    @task_grade.task_id = task_id
    @task_grade.profile_id = profile_id
    @task_grade.grade = task_grade
    @task_grade.save
    return ""
  end
  
  def self.task_grade_update(task_grade,grade_obj)
    grade = grade_obj.grade
    grade_obj.update_attribute('grade',task_grade)
    return grade
  end
  
  def self.load_task_grade(school_id, course_id,task_id,profile_id)
    task_grade = TaskGrade.where("school_id = ? and course_id = ? and task_id = ? and profile_id = ?",school_id, course_id,task_id,profile_id).first
    if task_grade.nil?
      return nil
    else
      return task_grade.grade 
    end
  end  

end
