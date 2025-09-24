class AddResourceFieldsToAttachment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :attachments, :resource_file_name, :string
    add_column :attachments, :resource_content_type, :string
    add_column :attachments, :resource_file_size, :integer
  end

  def self.down
    remove_column :attachments, :resource_file_name
    remove_column :attachments, :resource_content_type
    remove_column :attachments, :resource_file_size
  end
end
