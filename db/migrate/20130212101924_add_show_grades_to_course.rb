class AddShowGradesToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :show_grade, :boolean, :default => true
  end
end
