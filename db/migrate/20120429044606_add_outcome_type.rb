class AddOutcomeType < ActiveRecord::Migration[4.2]
  def up
    add_column :outcomes, :shared, :boolean, default: false
  end

  def down
    remove_column :outcomes, :shared
  end
end
