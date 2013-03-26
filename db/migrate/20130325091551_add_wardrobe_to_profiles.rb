class AddWardrobeToProfiles < ActiveRecord::Migration
  def change
    add_column :profiles, :wardrobe, :integer, :default => 1
  end
end
