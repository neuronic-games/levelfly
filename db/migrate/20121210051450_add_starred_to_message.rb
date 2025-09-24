class AddStarredToMessage < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :starred, :boolean, default: false
  end
end
