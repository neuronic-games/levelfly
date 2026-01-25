class AddBadgeImageIdToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :badge_image_id, :integer
  end
end
