class AddImageToGames < ActiveRecord::Migration[4.2]
  def self.up
    add_column :games, :image_file_name, :string
    add_column :games, :image_content_type, :string
    add_column :games, :image_file_size, :integer
  end

  def self.down
    remove_column :games, :image_file_name
    remove_column :games, :image_content_type
    remove_column :games, :imagee_file_size
  end
end
