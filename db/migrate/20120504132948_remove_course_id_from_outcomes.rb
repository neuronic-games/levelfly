class RemoveCourseIdFromOutcomes < ActiveRecord::Migration[4.2]
  def up
    remove_column :outcomes, :course_id
  end

  def down
    add_column :outcomes, :course_id, :integer
  end
end
