class AddProfileIdAndGiverProfileIdToAvatarBadges < ActiveRecord::Migration
  def change
    add_column :avatar_badges, :profile_id, :integer
    add_column :avatar_badges, :giver_profile_id, :integer
  end
end
