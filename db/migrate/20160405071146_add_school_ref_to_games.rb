class AddSchoolRefToGames < ActiveRecord::Migration
  def change
    add_column :games, :school_id, :integer, references: :schools
  end
end
