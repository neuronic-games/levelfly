class AddResourceFieldsToAttachment < ActiveRecord::Migration
  def self.up
    change_table :attachments do |t|
      t.has_attached_file :resource
    end
  end

  def self.down
    drop_attached_file :attachments, :resource
  end
end
