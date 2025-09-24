class AddWallToFeed < ActiveRecord::Migration[4.2]
  def up
    add_column :feeds, :wall_id, :integer
  end

  def down
    remove_column :feeds, :wall_id
  end
end
