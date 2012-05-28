class AddIamgeFileNameToGroup < ActiveRecord::Migration
  def change
    add_column :groups, :image_file_name, :string
    add_column :groups, :image_content_type, :string
    add_column :groups, :image_file_size	, :integer
  end
end
