class CreateWardrobes < ActiveRecord::Migration
  def change
    create_table :wardrobes do |t|
      t.string :name, limit: 64
      t.date :available_date
      t.integer :available_level
      t.date :visible_date
      t.integer :visible_level
      t.boolean :archived, default: false

      t.timestamps
    end
  end
end
