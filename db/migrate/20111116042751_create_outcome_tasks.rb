class CreateOutcomeTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :outcome_tasks do |t|
      t.integer :task_id
      t.integer :outcome_id
      t.decimal :points_percentage

      t.timestamps
    end
  end
end
