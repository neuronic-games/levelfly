class AddTypeToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :parent_type, :string
  end
end
