class OutcomeGrade < ActiveRecord::Base

  def self.outcome_points(school_id,course_id,outcome_id, profile_id,points)
    @outcome_grade= OutcomeGrade.where("school_id = ? and course_id = ? and outcome_id =? and profile_id = ? ",school_id,course_id,outcome_id,profile_id).first
    if !@outcome_grade.nil?
      self.outcome_grade_update(school_id,course_id,outcome_id, profile_id,points,@outcome_grade)
    else
      self.outcome_grade_save(school_id,course_id,outcome_id, profile_id,points)
    end
  end

  def self.outcome_grade_save(school_id,course_id,outcome_id, profile_id,points)
   
    @outcome_grade = OutcomeGrade.new
    @outcome_grade.school_id = school_id
    @outcome_grade.course_id = course_id
    @outcome_grade.outcome_id = outcome_id
    @outcome_grade.profile_id = profile_id
    @outcome_grade.grade = points
    @outcome_grade.save
  end
  
  def self.outcome_grade_update(school_id,course_id,outcome_id, profile_id,points,outcome_grade)
     outcome_grade.update_attribute('grade',points)
  end

end
