class AddCreatorProfileIdToBadges < ActiveRecord::Migration
  def change
    add_column :badges, :creator_profile_id, :integer
  end
end
