class CreateJoinTableGameOutcome < ActiveRecord::Migration
  def change
    create_table :games_outcomes, :id => false do |t|
      t.references :game, :outcome
    end

    add_index :games_outcomes, [:game_id, :outcome_id]
  end
end
