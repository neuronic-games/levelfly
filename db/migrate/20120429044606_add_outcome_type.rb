class AddOutcomeType < ActiveRecord::Migration
  def up
    add_column :outcomes, :shared, :boolean, default: false
  end

  def down
    remove_column :outcomes, :shared
  end
end
