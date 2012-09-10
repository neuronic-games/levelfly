class AddStatusToUser < ActiveRecord::Migration
  def change
    add_column :users, :status, :string, :default =>"A", :limit=>1
  end
end
