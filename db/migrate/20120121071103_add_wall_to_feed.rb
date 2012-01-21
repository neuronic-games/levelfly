class AddWallToFeed < ActiveRecord::Migration
  def up
    add_column :feeds, :wall_id, :integer
  end

  def down
    remove_column :feeds, :wall_id
  end
end
