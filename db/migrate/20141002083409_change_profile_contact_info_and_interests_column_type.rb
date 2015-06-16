class ChangeProfileContactInfoAndInterestsColumnType < ActiveRecord::Migration
  def up
    change_column :profiles, :contact_info, :text
    change_column :profiles, :interests, :text
  end

  def down
    change_column :profiles, :contact_info, :string
    change_column :profiles, :interests, :string
  end
end
