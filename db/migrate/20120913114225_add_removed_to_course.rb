class AddRemovedToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :removed, :boolean, :default => false
  end
end
