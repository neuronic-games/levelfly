class AddCourseIdToAvatarBadges < ActiveRecord::Migration
  def up
    add_column :avatar_badges, :course_id, :integer
  end

  def down
    remove_column :avatar_badges, :course_id
  end
end
