class AddDisplayNumberGradesToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :display_number_grades, :boolean, default: false
  end
end
