class RemoveStatsFromAvatar < ActiveRecord::Migration
  def up
    remove_column :avatars, :level
    remove_column :avatars, :points
    remove_column :avatars, :badge_count
  end

  def down
    add_column :avatars, :level, :integer, default: 1
    add_column :avatars, :points, :integer, default: 0
    add_column :avatars, :badge_count, :integer, default: 0
  end
end
