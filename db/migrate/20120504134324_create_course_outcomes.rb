class CreateCourseOutcomes < ActiveRecord::Migration[4.2]
  def change
    create_table :courses_outcomes, id: false do |t|
      t.references :course, :outcome
    end

    add_index :courses_outcomes, %i[course_id outcome_id]
  end
end
