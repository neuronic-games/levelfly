class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.integer :profile_id
      t.integer :about_object_id
      t.string :about_object_type, :limit=>64
      t.text :content

      t.timestamps
    end
  end
end
