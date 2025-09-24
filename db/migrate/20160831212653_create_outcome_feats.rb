class CreateOutcomeFeats < ActiveRecord::Migration[4.2]
  def change
    create_table :outcome_feats do |t|
      t.integer :feat_id
      t.integer :outcome_id
      t.integer :profile_id
      t.integer :rating # 1-3 bronze/silver/gold

      t.timestamps
    end
    add_index(:outcome_feats, %i[profile_id outcome_id feat_id])
  end
end
