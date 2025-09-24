class CreateGradeTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :grade_types do |t|
      t.integer  :school_id
      t.integer  :course_id
      t.string   :letter,                   limit: 2
      t.decimal  :value,                    precision: 4, scale: 2
      t.decimal  :value_min,                precision: 4, scale: 2
      t.decimal  :gpa,                      default: 0.0, null: false, precision: 2, scale: 1
      t.timestamps
    end
    add_index :grade_types, :school_id
    add_index :grade_types, :course_id
  end
end
