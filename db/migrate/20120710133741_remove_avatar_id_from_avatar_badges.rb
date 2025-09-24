class RemoveAvatarIdFromAvatarBadges < ActiveRecord::Migration[4.2]
  def up
    remove_column :avatar_badges, :avatar_id
  end

  def down
    add_column :avatar_badges, :avatar_id, :integer
  end
end
