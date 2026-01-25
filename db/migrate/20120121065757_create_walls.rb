class CreateWalls < ActiveRecord::Migration[4.2]
  def change
    create_table :walls do |t|
      t.integer :parent_id
      t.string :parent_type

      t.timestamps
    end
  end
end
