class AddCourseIdToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :course_id, :integer, default: 0
  end
end
