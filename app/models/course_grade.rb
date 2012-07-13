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
    cg = CourseGrade.where(:profile_id => profile_id, :course_id => course_id, :outcome_id => outcome_id).first
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
  def self.load_grade(profile_id, course_id,school_id)
    cg_list = CourseGrade.where(:profile_id => profile_id, :course_id => course_id, :school_id => school_id)
    
    course_grades = {}
    outcome_grades = {}
    cg_list.each do |cg|
      if cg.outcome_id.nil?
        course_grades[cg.course_id] = cg.grade
      else
        outcome_grades[cg.course_id] = {} if outcome_grades[cg.course_id].nil?
        outcome_grades[cg.outcome_id] = cg.grade
      end
    end
    
    return course_grades, outcome_grades
  end
  
  def self.load_outcomes(profile_id, course_id,outcome_id,school_id)
    outcome_point = CourseGrade.where("school_id = ? and profile_id = ? and course_id = ? and outcome_id = ?",school_id, profile_id, course_id,outcome_id).first
    if outcome_point.nil?
      return ""
    else
      return outcome_point.grade
    end
  end
  
  def self.load_notes(profile_id, course_id,school_id)
    course_notes = CourseGrade.where("school_id = ? and profile_id = ? and course_id = ? and outcome_id IS NULL",school_id, profile_id, course_id).first
    if course_notes.nil?
      return ""
    else
      return course_notes.notes
    end
  end
  
  def self.save_notes(profile_id, course_id,school_id,notes)
     course_notes = CourseGrade.where("school_id = ? and profile_id = ? and course_id = ? and outcome_id IS NULL",school_id, profile_id, course_id).first
     course_notes.notes = notes
     course_notes.save
  end
  
  def self.get_outcomes(course_id,outcomes,school_id,profile_id)
    points = []
    grade =""
    course_xp = TaskGrade.select("sum(points) as total").where("school_id = ? and course_id = ? and profile_id = ?",school_id,course_id,profile_id)
    outcomes.each do |o|
      #@students = CourseGrade.find(:all, :conditions=>["school_id = ? and course_id = ? and outcome_id = ?",school_id,course_id,o.id], :limit => 1, :order => 'grade DESC')
      outcome_point = CourseGrade.where("school_id = ? and course_id = ? and outcome_id = ? and profile_id = ?",school_id,course_id,o.id,profile_id).first   
      if outcome_point.nil?
        grade =""
      else
        grade = outcome_point.grade
      end
      points.push(grade)
    end
    return points, course_xp.first.total
  end
  
  
end