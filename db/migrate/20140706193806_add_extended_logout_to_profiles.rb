class AddExtendedLogoutToProfiles < ActiveRecord::Migration
  def change
    add_column :profiles, :extended_logout, :boolean
  end
end
