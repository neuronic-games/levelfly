class AddInterestsToProfile < ActiveRecord::Migration
  def change
    add_column :profiles, :interests, :string
  end
end
