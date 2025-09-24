class AddSchoolRefToGames < ActiveRecord::Migration[4.2]
  def change
    add_column :games, :school_id, :integer, references: :schools
  end
end
