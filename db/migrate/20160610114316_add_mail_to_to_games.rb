class AddMailToToGames < ActiveRecord::Migration
  def change
    add_column :games, :mail_to, :string
  end
end
