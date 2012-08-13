class CreateRewards < ActiveRecord::Migration
  def change
    create_table :rewards do |t|
      t.integer :xp
      t.string :object_type, :limit=>16
      t.integer :object_id
  
      t.timestamps
    end
  end
end
