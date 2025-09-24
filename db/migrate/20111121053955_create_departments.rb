class CreateDepartments < ActiveRecord::Migration[4.2]
  def change
    create_table :departments do |t|
      t.string :name, limit: 64
      t.text :descr
      t.string :code
      t.boolean :archived

      t.timestamps
    end
  end
end
