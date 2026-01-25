class AddTypeToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :parent_type, :string, limit: 1, default: 'C'
  end
end
