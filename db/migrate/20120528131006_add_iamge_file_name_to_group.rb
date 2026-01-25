class AddIamgeFileNameToGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :image_file_name, :string
    add_column :groups, :image_content_type, :string
    add_column :groups, :image_file_size, :integer
  end
end
