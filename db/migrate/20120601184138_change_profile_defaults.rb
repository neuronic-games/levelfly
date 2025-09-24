class ChangeProfileDefaults < ActiveRecord::Migration[4.2]
  def up
    change_column :profiles, :like_given, :integer, default: 0
    change_column :profiles, :like_received, :integer, default: 0
    change_column :profiles, :post_count, :integer, default: 0
    Profile.where(like_given: nil).update_all(like_given: 0)
    Profile.where(like_received: nil).update_all(like_received: 0)
    Profile.where(post_count: nil).update_all(post_count: 0)
  end

  def down; end
end
