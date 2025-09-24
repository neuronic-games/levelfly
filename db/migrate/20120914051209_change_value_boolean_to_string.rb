class ChangeValueBooleanToString < ActiveRecord::Migration[4.2]
  def up
    change_column :settings, :value, :string
  end

  def down; end
end
