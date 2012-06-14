class CreateSchoolGrades < ActiveRecord::Migration
  def change
    create_table :school_grades do |t|
      t.integer  :school_id
      t.string   :letter,                   :limit => 3
      t.integer  :percent_min
      t.integer  :percent_max
      t.decimal  :value,                    :default => 0.0, :null => false, :precision => 2, :scale => 1
      t.timestamps
    end
    add_index :school_grades, :school_id
  end
end
