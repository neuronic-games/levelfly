class RemoveCampusIdFromMajor < ActiveRecord::Migration
  def up
    remove_column :majors, :campus_id
  end

  def down
    add_column :majors, :campus_id, :integer
  end
end
