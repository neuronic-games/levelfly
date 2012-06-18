# Holds the final grades per student for each course and outcome. These are the calculated averages
# for effenciency. The values must be upated whenever TaskGrade and OutcomeGrade values are changed.

class CourseGrade < ActiveRecord::Base
  belongs_to :school
  belongs_to :course
  belongs_to :outcome
  belongs_to :profile
  
  # If outcome_id is nil, the grade is a percent grade for the course. If outcome_id is present,
  # the grade is a outcome grade 1-3.
  def self.save_grade(profile_id, grade, course_id, outcome_id = nil)
    cg = CourseGrade.find(:first, 
      :conditions => {:profile_id => profile_id, :course_id => course_id, :outcome_id => outcome_id})
    if cg.nil?
      profile = Profile.find(profile_id)
      school_id = profile.school_id
      cg = CourseGrade.create(
        :school_id => school_id, 
        :profile_id => profile_id, 
        :course_id => course_id, 
        :outcome_id => outcome_id,
        :grade => grade
      )
    else
      cg.grade = grade
      cg.save
    end
    return cg
  end
  
  # Returns two hashes of course and outcome grades. The key is the course_id. Outcome grades are represented
  # as a hash of a hash.
  def self.load_grade(profile_id, course_id)
    cg_list = CourseGrade.find(:all, :conditions => {:profile_id => profile_id, :course_id => course_id})
    
    course_grades = {}
    outcome_grades = {}
    cg_list.each do |cg|
      if cg.outcome_id.nil?
        course_grades[cg.course_id] = cg.grade
      else
        outcome_grades[cg.course_id] = {} if outcome_grades[cg.course_id].nil?
        outcome_grades[cg.course_id][cg.outcome_id] = cg.grade
      end
    end
    
    return course_grades, outcome_grades
  end
  
end
