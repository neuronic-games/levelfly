class AddTaskIdtoOutcomeGrade < ActiveRecord::Migration[4.2]
  def up
    add_column :outcome_grades, :task_id, :integer
  end

  def down
    remove_column :outcome_grades, :task_id
  end
end
