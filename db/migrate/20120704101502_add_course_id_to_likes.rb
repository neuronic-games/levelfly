class AddCourseIdToLikes < ActiveRecord::Migration
  def up
    add_column :likes, :course_id, :integer
  end

  def down
   remove_column :likes, :course_id
  end
end
