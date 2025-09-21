class AddAvailableBadgeImageIdToBadges < ActiveRecord::Migration
  def change
    add_column :badges, :available_badge_image_id, :integer
  end
end
