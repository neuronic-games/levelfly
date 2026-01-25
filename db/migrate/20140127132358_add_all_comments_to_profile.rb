class AddAllCommentsToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :all_comments, :boolean, default: true
  end
end
