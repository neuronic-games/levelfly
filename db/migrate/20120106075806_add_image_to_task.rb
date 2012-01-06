class AddImageToTask < ActiveRecord::Migration
  def self.up
    add_column :tasks, :image_file_name, :string
    add_column :tasks, :image_content_type, :string
    add_column :tasks, :image_file_size, :integer
  end

  def self.down
    remove_column :tasks, :image_file_name
    remove_column :tasks, :image_content_type
    remove_column :tasks, :imagee_file_size
  end
end
