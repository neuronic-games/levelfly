class AddLevelToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :level, :integer
  end
end
