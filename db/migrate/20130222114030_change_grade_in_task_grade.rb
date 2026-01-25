class ChangeGradeInTaskGrade < ActiveRecord::Migration[4.2]
  def up
    change_table :task_grades do |t|
      t.change :grade, :decimal, default: 0.0, precision: 5, scale: 2
    end
  end

  def down
    change_table :task_grades do |t|
      t.change :grade, :integer
    end
  end
end
