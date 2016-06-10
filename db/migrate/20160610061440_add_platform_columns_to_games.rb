class AddPlatformColumnsToGames < ActiveRecord::Migration
  def change
  	add_column :games, :download_links, :text
  end
end
