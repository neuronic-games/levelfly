class CreateLikes < ActiveRecord::Migration[4.2]
  def change
    create_table :likes do |t|
      t.integer :profile_id
      t.integer :message_id

      t.timestamps
    end
  end
end
