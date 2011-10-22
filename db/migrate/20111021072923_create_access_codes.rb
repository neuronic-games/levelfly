class CreateAccessCodes < ActiveRecord::Migration
  def change
    create_table :access_codes do |t|
      t.integer :campus_id
      t.integer :major_id
      t.string :code, :limit=>32
      t.date :available_date
      t.boolean :archived, :default => false

      t.timestamps
    end
  end
end
