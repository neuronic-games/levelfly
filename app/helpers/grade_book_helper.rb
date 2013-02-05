module GradeBookHelper
  
  def load_caregory_name(task_id)
    task = Task.find(task_id)
    if task.category
      return "  (#{task.category.name}) "
    end
   return "  (Uncategorized)"
  end
  
end
