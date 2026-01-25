class CreateSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :settings do |t|
      t.integer :object_id
      t.string :object_type
      t.string :name
      t.boolean :value, default: false
      t.timestamps
    end
  end
end
