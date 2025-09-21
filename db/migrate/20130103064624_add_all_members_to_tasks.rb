class AddAllMembersToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :all_members, :boolean, default: false
  end
end
