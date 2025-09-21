class AddDisplayNumberGradesToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :display_number_grades, :boolean, default: false
  end
end
