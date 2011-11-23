class AddLevelToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :level, :integer
  end
end
