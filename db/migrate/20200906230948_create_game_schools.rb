class CreateGameSchools < ActiveRecord::Migration
  def change
    create_table :game_schools do |t|
      t.integer :game_id
      t.integer :school_id

      t.timestamps null: false
    end
    add_index :game_schools, %i[game_id school_id]
  end
end
