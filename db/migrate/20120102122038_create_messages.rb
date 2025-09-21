class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :profile_id
      t.integer :parent_id
      t.string :parent_type, limit: 64
      t.text :content
      t.datetime :post_date
      t.boolean :archived

      t.timestamps
    end
  end
end
