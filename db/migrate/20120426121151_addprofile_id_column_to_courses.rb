class AddprofileIdColumnToCourses < ActiveRecord::Migration
  def up
    add_column :courses, :profile_id, :integer
  end

  def down; end
end
