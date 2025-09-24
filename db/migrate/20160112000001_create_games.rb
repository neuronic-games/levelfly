class CreateGames < ActiveRecord::Migration[4.2]
  def change
    create_table :games do |t|
      t.string :handle
      t.string :name
      t.text :descr
      t.string :image
      t.string :last_rev
      t.datetime :last_rev_date
      t.integer :player_count,        default: 0
      t.boolean :published,           default: false
      t.datetime :first_publish_date
      t.boolean :archived, default: false

      t.timestamps
    end

    add_index :games, %i[archived published handle]
    add_index :games, %i[archived published name]
  end
end
