class CreateMajors < ActiveRecord::Migration
  def change
    create_table :majors do |t|
      t.string :name, :limit=>64
      t.string :code, :limit=>32
      t.boolean :archived

      t.timestamps
    end
  end
end
