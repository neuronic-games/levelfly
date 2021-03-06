class AddMessageTypeToMessage < ActiveRecord::Migration
  def self.up
    add_column :messages, :message_type, :string, :default=>"Message", :limit=>32
  end

  def self.down
    remove_column :messages, :message_type
  end
end
