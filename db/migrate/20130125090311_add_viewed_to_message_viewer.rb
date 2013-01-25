class AddViewedToMessageViewer < ActiveRecord::Migration
  def change
    add_column :message_viewers, :viewed, :boolean, :default => false
  end
end
