class AddStarredToAttachments < ActiveRecord::Migration[4.2]
  def change
    add_column :attachments, :starred, :boolean, default: false
  end
end
