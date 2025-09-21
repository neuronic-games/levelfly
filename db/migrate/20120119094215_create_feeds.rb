class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.integer :profile_id
      t.integer :object_id
      t.string :object_type, limit: 64

      t.timestamps
    end
  end
end
