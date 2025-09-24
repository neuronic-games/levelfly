class ChangesToCategories < ActiveRecord::Migration[4.2]
  def up
    add_column :categories, :percent_value, :integer
    add_column :categories, :campus_id, :integer
    remove_column :categories, :descr
  end

  def down
    remove_column :categories, :percent_value, :integer
    remove_column :categories, :campus_id, :integer
    add_column :categories, :descr
  end
end
