class RenameCampusToSchool < ActiveRecord::Migration[4.2]
  def up
    rename_table :campus, :schools
  end

  def down
    rename_table :schools, :campus
  end
end
