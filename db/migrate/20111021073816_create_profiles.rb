class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.integer :user_id
      t.integer :campus_id
      t.integer :major_id
      t.string :code, :limit=>64
      t.string :name, :limit=>64
      t.string :full_name, :limit=>64
      t.string :salutation, :limit=>64
      t.boolean :primary
      t.boolean :archived

      t.timestamps
    end
  end
end
