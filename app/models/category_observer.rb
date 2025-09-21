class CategoryObserver < ActiveRecord::Observer
  def after_update(category)
    update_task_grade(category) if category.percent_value_changed?
  end

  def after_destroy(category)
    update_task_grade(category)
  end

  private

  def update_task_grade(category)
    tasks = Task.where(['category_id = ? and archived = ?', category.id, false])
    if tasks
      tasks.each do |task|
        task.grade_recalculate
      end
    end
  end
end
