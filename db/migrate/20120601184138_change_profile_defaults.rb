class ChangeProfileDefaults < ActiveRecord::Migration
  def up
    change_column :profiles, :like_given, :integer, :default => 0
    change_column :profiles, :like_received, :integer, :default => 0
    change_column :profiles, :post_count, :integer, :default => 0
    Profile.update_all("like_given = 0", "like_given is null")
    Profile.update_all("like_received = 0", "like_received is null")
    Profile.update_all("post_count = 0", "post_count is null")
  end

  def down
  end
end
