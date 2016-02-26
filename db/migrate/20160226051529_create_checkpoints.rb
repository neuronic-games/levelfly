class CreateCheckpoints < ActiveRecord::Migration
  def change
    create_table :checkpoints do |t|
      t.integer :game_id,         :null => false
      t.integer :profile_id,      :null => false
      t.text    :checkpoint
      
      t.timestamps
    end
    add_index :checkpoints, [:profile_id, :game_id]
  end
end
