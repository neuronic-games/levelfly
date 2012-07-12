class AddStarredToAttachments < ActiveRecord::Migration
  def change
   add_column :attachments, :starred, :boolean, :default => false
  end
end
