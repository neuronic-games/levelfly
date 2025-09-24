class CreateCategories < ActiveRecord::Migration[4.2]
  def change
    create_table :categories do |t|
      t.string :name, limit: 64
      t.text :descr
      t.boolean :archived

      t.timestamps
    end
  end
end
