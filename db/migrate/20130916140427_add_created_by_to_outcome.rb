class AddCreatedByToOutcome < ActiveRecord::Migration
  def change
    add_column :outcomes, :created_by, :integer
  end
end
