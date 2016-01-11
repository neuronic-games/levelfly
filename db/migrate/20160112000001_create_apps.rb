class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :app_code
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

      t.references :school

      t.timestamps
    end

    add_index :apps, [:archived, :published, :school_id, :app_id]
    add_index :apps, [:archived, :published, :school_id, :app_code]
    add_index :apps, [:archived, :published, :school_id, :name]
  end
end
