class AddBadgeImageIdToBadges < ActiveRecord::Migration
  def change
    add_column :badges, :badge_image_id, :integer
  end
end
