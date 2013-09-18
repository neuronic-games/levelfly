class CreateSemesters < ActiveRecord::Migration
  def change
    create_table :semesters do |t|
      t.string :name
      t.integer :start_month
      t.integer :end_month
      t.references :school

      t.timestamps
    end
    add_index :semesters, :school_id
  end
end
