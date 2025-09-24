class AddWardrobeToProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :wardrobe, :integer, default: 1
  end
end
