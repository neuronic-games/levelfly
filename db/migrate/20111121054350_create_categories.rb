class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name, limit: 64
      t.text :descr
      t.boolean :archived

      t.timestamps
    end
  end
end
