class AddLikeToMessage < ActiveRecord::Migration[4.2]
  def self.up
    add_column :messages, :like, :integer, default: 0
  end

  def self.down
    remove_column :messages, :like
  end
end
