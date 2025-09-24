class CreateMajors < ActiveRecord::Migration[4.2]
  def change
    create_table :majors do |t|
      t.integer   :school_id
      t.string    :name,      limit: 64
      t.string    :code,      limit: 32
      t.boolean   :archived,  default: false
      t.timestamps
    end
  end
end
