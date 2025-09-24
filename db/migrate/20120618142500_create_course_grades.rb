class CreateCourseGrades < ActiveRecord::Migration[4.2]
  def change
    create_table :course_grades do |t|
      t.integer  :school_id
      t.integer  :course_id
      t.integer  :outcome_id
      t.integer  :profile_id
      t.decimal  :grade, default: 0.0, precision: 4, scale: 2
      t.timestamps
    end
    add_index :course_grades, %i[profile_id course_id outcome_id]
  end
end
