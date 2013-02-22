class ChangeGradeInCourseGrade < ActiveRecord::Migration
  def up
    change_table :course_grades do |t|
      t.change :grade, :decimal, :default => 0.0, :precision => 5, :scale => 2
    end
  end

  def down
    change_table :course_grades do |t|
      t.change :grade, :integer, :default => 0.0, :precision => 4, :scale => 2
    end
  end
end
