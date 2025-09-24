class AddProfileIdToGames < ActiveRecord::Migration[4.2]
  def change
    add_column :games, :profile_id, :integer
  end
end
