class AddprofileIdColumnToCourses < ActiveRecord::Migration[4.2]
  def up
    add_column :courses, :profile_id, :integer
  end

  def down; end
end
