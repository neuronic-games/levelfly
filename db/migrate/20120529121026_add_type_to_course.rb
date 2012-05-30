class AddTypeToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :parent_type, :string, :limit => 1, :default => 'C'
  end
end
