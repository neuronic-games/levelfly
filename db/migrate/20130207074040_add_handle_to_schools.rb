class AddHandleToSchools < ActiveRecord::Migration[4.2]
  def change
    add_column :schools, :handle, :string, limit: 16
  end
end
