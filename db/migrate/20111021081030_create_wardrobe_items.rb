class CreateWardrobeItems < ActiveRecord::Migration
  def change
    create_table :wardrobe_items do |t|
      t.integer :wardrobe_id
      t.string :name, :limit=>64
      t.string :image_file, :limit=>64
      t.integer :parent_item_id
      t.date :available_date
      t.integer :available_level
      t.date :visible_date
      t.integer :visible_level
      t.boolean :archived, :default => false

      t.timestamps
    end
  end
end
