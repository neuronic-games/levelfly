class CreateFeats < ActiveRecord::Migration[4.2]
  def change
    create_table :feats do |t|
      t.integer :game_id,         null: false
      t.integer :profile_id,      null: false

      t.integer :progress
      t.integer :progress_type, null: false
      t.string  :level

      t.timestamps
    end

    add_index :feats, %i[profile_id game_id]
  end
end
