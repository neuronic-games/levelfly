class CreateTaskGrades < ActiveRecord::Migration
  def change
    create_table :task_grades do |t|
      t.integer :campus_id
      t.integer :course_id
      t.integer :task_id
      t.integer :profile_id
      t.integer :grade

      t.timestamps
    end
  end
end
