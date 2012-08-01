class AddTopicToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :topic, :string
  end
end
