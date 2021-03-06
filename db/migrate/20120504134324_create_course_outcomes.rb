class CreateCourseOutcomes < ActiveRecord::Migration
  def change
    create_table :courses_outcomes, :id => false do |t|
      t.references :course, :outcome
    end

    add_index :courses_outcomes, [:course_id, :outcome_id]
  end
end
