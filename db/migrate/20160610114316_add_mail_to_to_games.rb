class AddMailToToGames < ActiveRecord::Migration[4.2]
  def change
    add_column :games, :mail_to, :string
  end
end
