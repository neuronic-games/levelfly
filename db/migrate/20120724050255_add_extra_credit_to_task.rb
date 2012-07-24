class AddExtraCreditToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :extra_credit, :boolean, :default => false
  end
end
