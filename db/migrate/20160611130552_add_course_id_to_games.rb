class AddCourseIdToGames < ActiveRecord::Migration
  def change
    add_column :games, :course_id, :integer
  end
end
