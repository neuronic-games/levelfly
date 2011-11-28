class RenameCampusToSchool < ActiveRecord::Migration
  def up
    rename_table :campus, :schools
  end

  def down
    rename_table :schools, :campus
  end
end
