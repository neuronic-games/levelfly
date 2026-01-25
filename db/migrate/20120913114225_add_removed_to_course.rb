class AddRemovedToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :removed, :boolean, default: false
  end
end
