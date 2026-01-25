class AddPlatformColumnsToGames < ActiveRecord::Migration[4.2]
  def change
    add_column :games, :download_links, :text
  end
end
