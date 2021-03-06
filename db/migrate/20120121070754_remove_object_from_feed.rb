class RemoveObjectFromFeed < ActiveRecord::Migration
  def up
    remove_column :feeds, :object_type
    remove_column :feeds, :object_id
  end

  def down
    add_column :feeds, :object_type, :string, :limit=>64
    add_column :feeds, :object_id, :integer
  end
end
