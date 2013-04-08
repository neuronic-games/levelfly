class AddShowOutcomesToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :show_outcomes, :boolean, :default => true
  end
end
