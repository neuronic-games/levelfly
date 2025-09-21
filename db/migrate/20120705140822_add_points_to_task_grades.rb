class AddPointsToTaskGrades < ActiveRecord::Migration
  def up
    add_column :task_grades, :points, :integer
  end

  def down
    remove_column :task_grades, :points
  end
end
