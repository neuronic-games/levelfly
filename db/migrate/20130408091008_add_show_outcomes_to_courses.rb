class AddShowOutcomesToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :show_outcomes, :boolean, default: true
  end
end
