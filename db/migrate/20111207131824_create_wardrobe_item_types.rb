class CreateWardrobeItemTypes < ActiveRecord::Migration
  def change
    create_table :wardrobe_item_types do |t|
      t.string :name, :limit=>32
      t.boolean :archived

      t.timestamps
    end
  end
end
