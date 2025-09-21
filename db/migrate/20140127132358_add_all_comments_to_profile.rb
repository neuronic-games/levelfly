class AddAllCommentsToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :all_comments, :boolean, default: true
  end
end
