class AddCourseIdToVarious < ActiveRecord::Migration[4.2]
  def self.up
    add_column :tasks, :course_id, :integer
    add_column :categories, :course_id, :integer
    add_column :outcomes, :course_id, :integer
  end

  def self.down
    remove_column :tasks, :course_id
    remove_column :categories, :course_id
    remove_column :outcomes, :course_id
  end
end
