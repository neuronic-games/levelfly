class AddAllMembersToCourses < ActiveRecord::Migration
  def change
    add_column :courses, :all_members, :boolean, :default => true
  end
end
