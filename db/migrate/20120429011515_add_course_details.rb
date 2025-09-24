class AddCourseDetails < ActiveRecord::Migration[4.2]
  def up
    add_column :courses, :section, :string, length: 3
    add_column :courses, :rating_low, :integer
    add_column :courses, :rating_medium, :integer
    add_column :courses, :rating_high, :integer
    add_column :courses, :tasks_low, :integer
    add_column :courses, :tasks_medium, :integer
    add_column :courses, :tasks_high, :integer
  end

  def down
    remove_column :courses, :section
    remove_column :courses, :rating_low
    remove_column :courses, :rating_medium
    remove_column :courses, :rating_high
    remove_column :courses, :tasks_low
    remove_column :courses, :tasks_medium
    remove_column :courses, :tasks_high
  end
end
