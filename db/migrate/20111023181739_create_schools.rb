class CreateSchools < ActiveRecord::Migration
  def change
    create_table :schools do |t|
      t.string    :name,      limit: 64
      t.string    :code,      limit: 64
      t.boolean   :archived, default: false
      t.timestamps
    end
  end
end
