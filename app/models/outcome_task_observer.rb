class OutcomeTaskObserver < ActiveRecord::Observer
  def after_destroy(outcome_task)
    current_task = outcome_task.task
    CourseGrade.update_outcome_average(outcome_task.outcome_id, current_task.id, current_task.course_id)
  end
end
