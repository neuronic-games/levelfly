class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.text :descr
      t.integer :course_id
      t.integer :task_id

      t.timestamps
    end
  end
end
