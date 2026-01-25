class AddWallToMessage < ActiveRecord::Migration[4.2]
  def up
    add_column :messages, :wall_id, :integer
  end

  def down
    remove_column :messages, :wall_id
  end
end
