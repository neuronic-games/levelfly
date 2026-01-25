class AddNotesFieldToCourseGrades < ActiveRecord::Migration[4.2]
  def up
    add_column :course_grades, :notes, :string
  end

  def down
    remove_column :course_grades, :notes
  end
end
