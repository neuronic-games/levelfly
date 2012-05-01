class RemoveProfileIdFromCourse < ActiveRecord::Migration
  def up
    remove_column :courses, :profile_id
  end

  def down
    add_column :courses, :profile_id, :integer
  end
end
