class CreateCampusMajors < ActiveRecord::Migration
  def change
    create_table :campus_majors do |t|
      t.integer :campus_id
      t.integer :major_id

      t.timestamps
    end
  end
end
