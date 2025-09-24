class AddAvailableBadgeImageIdToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :available_badge_image_id, :integer
  end
end
