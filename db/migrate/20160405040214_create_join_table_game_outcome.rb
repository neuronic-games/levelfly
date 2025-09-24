class CreateJoinTableGameOutcome < ActiveRecord::Migration[4.2]
  def change
    create_table :games_outcomes, id: false do |t|
      t.references :game, :outcome
    end

    add_index :games_outcomes, %i[game_id outcome_id]
  end
end
