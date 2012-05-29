class RenameTypeToCourses < ActiveRecord::Migration
  def up
  rename_column :courses, :type, :parent_type
  end

  def down
  end
end
