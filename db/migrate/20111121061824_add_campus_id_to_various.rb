class AddCampusIdToVarious < ActiveRecord::Migration[4.2]
  def self.up
    add_column :tasks, :campus_id, :integer
    add_column :quests, :campus_id, :integer
    add_column :departments, :campus_id, :integer
    add_column :majors, :campus_id, :integer
  end

  def self.down
    remove_column :tasks, :campus_id
    remove_column :quests, :campus_id
    remove_column :departments, :campus_id
    remove_column :majors, :campus_id
  end
end
