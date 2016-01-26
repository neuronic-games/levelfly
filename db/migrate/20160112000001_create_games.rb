class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :handler
      t.string :name
      t.text :descr
      t.string :image
      t.string :last_rev
      t.datetime :last_rev_date
      t.integer :player_count
      t.boolean :published
      t.datetime :first_publish_date
      t.boolean :archived
      t.integer :player_count

      t.timestamps
    end

    add_index :games, [:archived, :published, :handler]
    add_index :games, [:archived, :published, :name]
  end
end
