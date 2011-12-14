class CreateVaults < ActiveRecord::Migration
  def change
    create_table :vaults do |t|
      t.string :vault_type, :limit=>32
      t.integer :object_id
      t.string :object_type, :limit=>64
      t.string :account
      t.string :secret
      t.string :folder

      t.timestamps
    end
  end
end
