module GradeBookHelper
  include ActionView::Helpers::NumberHelper

  def load_caregory_name(task_id)
    task = Task.find(task_id)
    if task.category
      return "  (#{task.category.name} #{number_with_precision(task.category.percent_value, :precision => 2) || 0}%) "
    end
   return "  (Uncategorized 0%)"
  end
  
end
