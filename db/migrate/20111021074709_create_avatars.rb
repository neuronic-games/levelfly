class CreateAvatars < ActiveRecord::Migration
  def change
    create_table :avatars do |t|
      t.integer :profile_id
      t.integer :level
      t.integer :points
      t.integer :badge_count
      t.integer :skin
      t.string :body, :limit=>64
      t.string :head, :limit=>64
      t.string :hair, :limit=>64
      t.string :hair_back, :limit=>64
      t.string :facial_1, :limit=>64
      t.string :facial_2, :limit=>64
      t.string :glasses, :limit=>64
      t.string :makeup, :limit=>64
      t.string :hat, :limit=>64
      t.string :earrings, :limit=>64
      t.string :jewelry, :limit=>64
      t.string :necklace, :limit=>64
      t.string :top, :limit=>64
      t.string :top_back, :limit=>64
      t.string :bottom, :limit=>64
      t.string :bottom_back, :limit=>64
      t.string :shoes, :limit=>64
      t.string :prop_1, :limit=>64
      t.string :prop_2, :limit=>64	
      t.string :background, :limit=>64
      t.boolean :archived, :default => false

      t.timestamps
    end
  end
end
