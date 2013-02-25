class ChangeDefaultGradeInTaskGrade < ActiveRecord::Migration
  def up
    change_table :task_grades do |t|
      t.change :grade, :decimal, :precision => 5, :scale => 2, :default => nil
    end
  end

  def down
    change_table :task_grades do |t|
      t.change :grade, :integer
    end
  end
end
