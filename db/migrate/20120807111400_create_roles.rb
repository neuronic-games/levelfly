class CreateRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :roles do |t|
      t.string :name, limit: 16
      t.integer :profile_id
      t.timestamps
    end
    add_index :roles, :name
  end
end
