class CreateOutcomes < ActiveRecord::Migration[4.2]
  def change
    create_table :outcomes do |t|
      t.string :name, limit: 64
      t.text :descr
      t.integer :category_id

      t.timestamps
    end
  end
end
