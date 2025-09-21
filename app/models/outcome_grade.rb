class OutcomeGrade < ActiveRecord::Base
  def self.outcome_points(school_id, course_id, outcome_id, profile_ids, average, task_id, outcome_val)
    data_arr = []
    profile_ids.each_with_index do |profile_id, i|
      @outcome_grade = OutcomeGrade.where(
        'school_id = ? and course_id = ? and outcome_id =? and profile_id = ? and task_id = ?', school_id, course_id, outcome_id, profile_id, task_id
      ).first
      outcome_val[i] = nil if outcome_val[i].blank?
      average[i] = nil if average[i].blank?
      CourseGrade.save_grade(profile_id, average[i], course_id, school_id, outcome_id)
      if @outcome_grade.nil?
        data_arr.push(outcome_grade_save(school_id, course_id, outcome_id, profile_id, task_id, outcome_val[i]))
      else
        data_arr.push(outcome_grade_update(outcome_val[i], @outcome_grade))
      end
    end
    data_arr
  end

  def self.outcome_grade_save(school_id, course_id, outcome_id, profile_id, task_id, outcome_val)
    @outcome_grade = OutcomeGrade.new
    @outcome_grade.school_id = school_id
    @outcome_grade.course_id = course_id
    @outcome_grade.outcome_id = outcome_id
    @outcome_grade.profile_id = profile_id
    @outcome_grade.grade = outcome_val
    @outcome_grade.task_id = task_id
    @outcome_grade.save
    ''
  end

  def self.outcome_grade_update(outcome_val, outcome_grade)
    grade = outcome_grade.grade
    outcome_grade.update_attribute('grade', outcome_val)
    grade
  end

  def self.load_task_outcomes(school_id, course_id, task_id, profile_id, outcome_id)
    outcome_point = OutcomeGrade.where(
      'school_id = ? and course_id = ? and task_id = ? and profile_id = ? and outcome_id = ?', school_id, course_id, task_id, profile_id, outcome_id
    ).first
    if outcome_point.nil?
      ''
    else
      outcome_point.grade
    end
  end
end
