class AddAllMembersToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :all_members, :boolean, default: false
  end
end
