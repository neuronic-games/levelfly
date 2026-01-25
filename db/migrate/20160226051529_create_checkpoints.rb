class CreateCheckpoints < ActiveRecord::Migration[4.2]
  def change
    create_table :checkpoints do |t|
      t.integer :game_id,         null: false
      t.integer :profile_id,      null: false
      t.text    :checkpoint

      t.timestamps
    end
    add_index :checkpoints, %i[profile_id game_id]
  end
end
