class CreateGroups < ActiveRecord::Migration[4.2]
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
