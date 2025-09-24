class AddpointsTotasks < ActiveRecord::Migration[4.2]
  def up
    add_column :tasks, :points, :integer, default: 0
  end

  def down
    remove_column :tasks, :points
  end
end
