class TaskObserver < ActiveRecord::Observer

  def after_update(task)
    task.grade_recalculate if task.category_id_changed? or task.archived_changed?
  end

end
