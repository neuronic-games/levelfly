class AddStatusToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :status, :string, default: 'A', limit: 1
  end
end
