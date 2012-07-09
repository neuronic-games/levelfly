class CreateBadgeImages < ActiveRecord::Migration
  def change
    create_table :badge_images do |t|
      t.string :image_file_name
      t.string :image_content_type
      t.integer :image_file_size
      t.timestamps
    end
  end
end
