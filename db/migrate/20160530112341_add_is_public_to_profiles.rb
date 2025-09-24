class AddIsPublicToProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :is_public, :boolean, default: true
    add_column :profiles, :friend_privilege, :boolean
  end
end
