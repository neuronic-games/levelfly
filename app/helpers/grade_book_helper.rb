module GradeBookHelper
  
  def load_caregory_name(task_id)
    task = Task.find(task_id)
    if task.category_id != 0 and !task.category_id.nil?
      return "(#{task.category.name})"
    end
   return nil 
  end
  
end
