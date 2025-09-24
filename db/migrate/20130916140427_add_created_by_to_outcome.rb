class AddCreatedByToOutcome < ActiveRecord::Migration[4.2]
  def change
    add_column :outcomes, :created_by, :integer
  end
end
