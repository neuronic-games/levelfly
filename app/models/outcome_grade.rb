class OutcomeGrade < ActiveRecord::Base

  def self.outcome_points(school_id,course_id,outcome_id, profile_id,average,task_id,outcome_val)
    @outcome_grade= OutcomeGrade.where("school_id = ? and course_id = ? and outcome_id =? and profile_id = ? and task_id = ?",school_id,course_id,outcome_id,profile_id,task_id).first
    if outcome_val.blank?
      outcome_val = nil
    end
    if average.blank?
      average = nil
    end
    if !@outcome_grade.nil?
      self.outcome_grade_update(outcome_val,@outcome_grade)
    else
      self.outcome_grade_save(school_id,course_id,outcome_id, profile_id,task_id,outcome_val)
    end
    CourseGrade.save_grade(profile_id, average, course_id,outcome_id)
  end

  def self.outcome_grade_save(school_id,course_id,outcome_id, profile_id,task_id,outcome_val)
    @outcome_grade = OutcomeGrade.new
    @outcome_grade.school_id = school_id
    @outcome_grade.course_id = course_id
    @outcome_grade.outcome_id = outcome_id
    @outcome_grade.profile_id = profile_id
    @outcome_grade.grade = outcome_val
    @outcome_grade.task_id = task_id
    @outcome_grade.save
  end
  
  def self.outcome_grade_update(outcome_val,outcome_grade)
     outcome_grade.update_attribute('grade',outcome_val)
  end
  
  def self.load_task_outcomes(school_id, course_id,task_id,profile_id,outcome_id)
    outcome_point = OutcomeGrade.where("school_id = ? and course_id = ? and task_id = ? and profile_id = ? and outcome_id = ?",school_id, course_id,task_id,profile_id,outcome_id).first
    if outcome_point.nil?
      return nil
    else
      return outcome_point.grade 
    end
  end  

end
