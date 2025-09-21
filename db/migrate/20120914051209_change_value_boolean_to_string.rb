class ChangeValueBooleanToString < ActiveRecord::Migration
  def up
    change_column :settings, :value, :string
  end

  def down; end
end
