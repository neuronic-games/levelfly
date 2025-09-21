class CreateTaskParticipants < ActiveRecord::Migration
  def change
    create_table :task_participants do |t|
      t.integer :profile_id
      t.integer :task_id
      t.datetime :assign_date
      t.datetime :complete_date
      t.string :profile_type, limit: 1
      t.string :priority, limit: 1
      t.string :status, limit: 1

      t.timestamps
    end
  end
end
