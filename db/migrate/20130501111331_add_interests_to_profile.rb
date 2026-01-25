class AddInterestsToProfile < ActiveRecord::Migration[4.2]
  def change
    add_column :profiles, :interests, :string
  end
end
