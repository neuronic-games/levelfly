class ChangeCourseParentType < ActiveRecord::Migration
  def up
    change_column :courses, :parent_type, :string, :limit => 1, :default => 'C'
    Course.update_all("parent_type = 'C'")
  end

  def down
  end
end
