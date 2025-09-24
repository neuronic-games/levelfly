class ChangeProfilePrivacyDefault < ActiveRecord::Migration[4.2]
  def up
    change_column :profiles, :is_public, :boolean, default: nil
    Profile.update_all('is_public = null')
  end

  def down
    change_column :profiles, :is_public, :boolean, default: true
    Profile.update_all('is_public = true', 'is_public is null')
  end
end
