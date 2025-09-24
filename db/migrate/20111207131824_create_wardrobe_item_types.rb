class CreateWardrobeItemTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :wardrobe_item_types do |t|
      t.string :name, limit: 32
      t.boolean :archived, default: false
      t.timestamps
    end
  end
end
