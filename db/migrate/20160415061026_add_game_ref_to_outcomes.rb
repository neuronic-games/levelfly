class AddGameRefToOutcomes < ActiveRecord::Migration
  def change
    add_column :outcomes, :game_id, :integer, references: :games
  end
end
