class AddtargetIdToMessages < ActiveRecord::Migration
  def up
  add_column :messages, :target_id, :integer
  add_column :messages, :target_type, :string
  end

  def down
  end
end
