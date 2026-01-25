class ChangeWardrobeImageLimit < ActiveRecord::Migration[4.2]
  def up
    change_column :wardrobe_items, :icon_file, :string, limit: 250
    change_column :wardrobe_items, :image_file, :string, limit: 250
  end

  def down
    change_column :wardrobe_items, :icon_file, :string, limit: 64
    change_column :wardrobe_items, :image_file, :string, limit: 64
  end
end
