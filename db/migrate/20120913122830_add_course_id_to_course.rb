class AddCourseIdToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :course_id, :integer, default: 0
  end
end
