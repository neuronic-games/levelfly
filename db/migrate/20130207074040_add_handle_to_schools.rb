class AddHandleToSchools < ActiveRecord::Migration
  def change
    add_column :schools, :handle, :string, limit: 16
  end
end
