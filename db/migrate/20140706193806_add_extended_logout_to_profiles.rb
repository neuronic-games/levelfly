class AddExtendedLogoutToProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :extended_logout, :boolean
  end
end
