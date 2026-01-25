class AddGameRefToOutcomes < ActiveRecord::Migration[4.2]
  def change
    add_column :outcomes, :game_id, :integer, references: :games
  end
end
