class AddStatsToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :xp, :integer, default: 0
    add_column :profiles, :badge_count, :integer, default: 0
    add_column :profiles, :level, :integer, default: 1
  end
end
