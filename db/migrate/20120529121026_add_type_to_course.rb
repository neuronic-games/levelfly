class AddTypeToCourse < ActiveRecord::Migration
  def change
    rename_column :courses, :type, :parent_type
  end
end
