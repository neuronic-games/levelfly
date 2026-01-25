class CreateObjectProfiles < ActiveRecord::Migration[4.2]
  def change
    create_table :object_profiles do |t|
      t.integer :object_id
      t.string :object_type, limit: 64
      t.integer :profile_id
      t.string :profile_type, limit: 1

      t.timestamps
    end
  end
end
