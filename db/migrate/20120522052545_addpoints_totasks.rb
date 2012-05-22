class AddpointsTotasks < ActiveRecord::Migration
  def up
  add_column :tasks, :points, :integer
  end

  def down
  end
end
