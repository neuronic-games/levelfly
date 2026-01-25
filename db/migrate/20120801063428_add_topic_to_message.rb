class AddTopicToMessage < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :topic, :string
  end
end
