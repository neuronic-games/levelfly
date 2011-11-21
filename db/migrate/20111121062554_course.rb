class Course < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :name, :limit=>64
      t.text :descr
      t.string :code
      t.integer :campus_id
      t.boolean :archived

      t.timestamps
    end
  end
end
