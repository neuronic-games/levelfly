class AddLikeToMessage < ActiveRecord::Migration
  def self.up
    add_column :messages, :like, :integer, :default=>0
  end

  def self.down
    remove_column :messages, :like
  end
end
