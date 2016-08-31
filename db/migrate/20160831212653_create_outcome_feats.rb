class CreateOutcomeFeats < ActiveRecord::Migration
  def change
    create_table :outcome_feats do |t|
      t.integer :feat_id
      t.integer :outcome_id
      t.integer :profile_id
      t.integer :rating # 1-3 bronze/silver/gold

      t.timestamps
    end
    add_index(:outcome_feats, [:profile_id, :outcome_id, :feat_id])
  end
end
