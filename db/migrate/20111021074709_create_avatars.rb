class CreateAvatars < ActiveRecord::Migration
  def change
    create_table :avatars do |t|
      t.integer :profile_id
      t.integer :level
      t.integer :points
      t.integer :badge_count
      t.integer :skin
      t.string :prop, :limit=>64	
      t.string :hat, :limit=>64
      t.string :hair, :limit=>64
      t.string :glasses, :limit=>64
      t.string :makeup, :limit=>64
      t.string :facial_hair, :limit=>64
      t.string :facial_marks, :limit=>64
      t.string :earrings, :limit=>64
      t.string :head, :limit=>64
      t.string :top, :limit=>64
      t.string :necklace, :limit=>64
      t.string :bottom, :limit=>64
      t.string :shoes, :limit=>64
      t.string :hair_back, :limit=>64
      t.string :hat_back, :limit=>64
      t.string :body, :limit=>64
      t.string :background, :limit=>64
      t.boolean :archived, :default => false

      t.timestamps
    end
  end
end
