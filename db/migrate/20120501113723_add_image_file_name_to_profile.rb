class AddImageFileNameToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :image_file_name, :string
    add_column :profiles, :image_content_type, :string
    add_column :profiles, :image_file_size, :integer
  end
end
