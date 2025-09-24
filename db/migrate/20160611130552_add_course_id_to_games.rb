class AddCourseIdToGames < ActiveRecord::Migration[4.2]
  def change
    add_column :games, :course_id, :integer
  end
end
