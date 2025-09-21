class AddpointsTotasks < ActiveRecord::Migration
  def up
    add_column :tasks, :points, :integer, default: 0
  end

  def down
    remove_column :tasks, :points
  end
end
