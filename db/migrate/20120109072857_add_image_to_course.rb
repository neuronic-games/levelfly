class AddImageToCourse < ActiveRecord::Migration
  def self.up
    add_column :courses, :image_file_name, :string
    add_column :courses, :image_content_type, :string
    add_column :courses, :image_file_size, :integer
  end

  def self.down
    remove_column :courses, :image_file_name
    remove_column :courses, :image_content_type
    remove_column :courses, :imagee_file_size
  end
end
