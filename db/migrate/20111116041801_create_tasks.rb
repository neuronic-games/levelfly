class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :name, :limit=>64
      t.text :descr
      t.date :due_date
      t.date :available_date
      t.date :visible_date
      t.integer :category_id
      t.boolean :notify_wall
      t.boolean :is_template
      t.boolean :archived

      t.timestamps
    end
  end
end
