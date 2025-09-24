class AddOwnerToAttachment < ActiveRecord::Migration[4.2]
  def up
    add_column :attachments, :owner_id, :integer
  end

  def down
    remove_column :attachments, :owner_id
  end
end
