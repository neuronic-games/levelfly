class AddViewedToMessageViewer < ActiveRecord::Migration[4.2]
  def change
    add_column :message_viewers, :viewed, :boolean, default: false
  end
end
