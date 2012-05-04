class RemoveCourseIdFromOutcomes < ActiveRecord::Migration
  def up
    remove_column :outcomes, :course_id
  end

  def down
    add_column :outcomes, :course_id, :integer
  end
end
