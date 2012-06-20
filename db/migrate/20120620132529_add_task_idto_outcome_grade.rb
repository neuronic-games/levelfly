class AddTaskIdtoOutcomeGrade < ActiveRecord::Migration
  def up
    add_column :outcome_grades, :task_id, :integer
  end

  def down
   remove_column :outcome_grades, :task_id
  end
end
