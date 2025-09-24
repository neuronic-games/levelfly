class AddExtraCreditToTask < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :extra_credit, :boolean, default: false
  end
end
