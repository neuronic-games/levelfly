class CreateQuests < ActiveRecord::Migration
  def change
    create_table :quests do |t|
      t.string :name, :limit=>64
      t.integer :points
      t.date :available_date
      t.integer :available_level
      t.date :visible_date
      t.integer :visible_level
      t.boolean :archived

      t.timestamps
    end
  end
end
