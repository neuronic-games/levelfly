class AddStarredToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :starred, :boolean, default: false
  end
end
