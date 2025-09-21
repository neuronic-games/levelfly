class RemoveAvatarIdFromAvatarBadges < ActiveRecord::Migration
  def up
    remove_column :avatar_badges, :avatar_id
  end

  def down
    add_column :avatar_badges, :avatar_id, :integer
  end
end
