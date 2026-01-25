class AddAllMembersToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :all_members, :boolean, default: true
  end
end
