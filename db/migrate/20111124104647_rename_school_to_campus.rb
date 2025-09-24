class RenameSchoolToCampus < ActiveRecord::Migration[4.2]
  def up
    rename_table :schools, :campus
  end

  def down
    rename_table :campus, :schools
  end
end
