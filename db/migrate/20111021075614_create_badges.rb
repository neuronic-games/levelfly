class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
      t.string :name, :limit=>64
      t.date :available_date
      t.integer :available_level
      t.date :visible_date
      t.integer :visible_level
      t.integer :quest_id
      t.boolean :archived

      t.timestamps
    end
  end
end
