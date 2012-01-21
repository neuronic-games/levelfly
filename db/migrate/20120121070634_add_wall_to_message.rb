class AddWallToMessage < ActiveRecord::Migration
  def up
    add_column :messages, :wall_id, :integer
  end

  def down
    remove_column :messages, :wall_id
  end
end
