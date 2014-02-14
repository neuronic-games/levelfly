class AddPostTimeFormatToProfile < ActiveRecord::Migration
  def up
    add_column :profiles, :post_date_format, :string, :length => 1, :default => 'D'
  end
  
  def down
    remove_column :profiles, :post_date_format
  end
end
