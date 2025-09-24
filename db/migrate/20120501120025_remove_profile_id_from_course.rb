class RemoveProfileIdFromCourse < ActiveRecord::Migration[4.2]
  def up
    remove_column :courses, :profile_id
  end

  def down
    add_column :courses, :profile_id, :integer
  end
end
