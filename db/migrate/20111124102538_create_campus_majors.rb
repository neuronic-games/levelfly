class CreateCampusMajors < ActiveRecord::Migration[4.2]
  def change
    create_table :campus_majors do |t|
      t.integer :campus_id
      t.integer :major_id

      t.timestamps
    end
  end
end
