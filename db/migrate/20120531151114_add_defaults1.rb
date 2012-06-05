class AddDefaults1 < ActiveRecord::Migration
  def up
    change_column :courses, :archived, :boolean, :default => false
    change_column :messages, :archived, :boolean, :default => false
    Course.update_all(["archived = ?", false], "archived is null")
    Message.update_all(["archived = ?", false], "archived is null")
  end

  def down
  end
end
