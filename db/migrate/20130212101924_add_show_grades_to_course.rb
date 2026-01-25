class AddShowGradesToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :show_grade, :boolean, default: true
  end
end
