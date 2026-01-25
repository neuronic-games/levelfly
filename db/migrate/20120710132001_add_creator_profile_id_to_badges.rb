class AddCreatorProfileIdToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :creator_profile_id, :integer
  end
end
