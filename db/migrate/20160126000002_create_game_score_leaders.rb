class CreateGameScoreLeaders < ActiveRecord::Migration
  def change
    create_table :game_score_leaders do |t|
      t.integer :game_id,         :null => false
      t.integer :profile_id,      :null => false
      t.string  :full_name
      t.integer :score
    end

    add_index :game_score_leaders, [:profile_id, :game_id]
  end
end
