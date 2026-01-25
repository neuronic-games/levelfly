class TaskObserver < ActiveRecord::Observer
  def after_update(task)
    task.grade_recalculate if task.category_id_changed? or task.archived_changed?
    return unless task.archived_changed?

    outcomes = task.outcomes
    outcomes.each do |outcome|
      CourseGrade.update_outcome_average(outcome.id, task.id, task.course_id) unless outcome.nil?
    end
  end
end
