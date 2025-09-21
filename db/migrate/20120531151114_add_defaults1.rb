class AddDefaults1 < ActiveRecord::Migration
  def up
    change_column :courses, :archived, :boolean, default: false
    change_column :messages, :archived, :boolean, default: false
  end

  def down; end
end
