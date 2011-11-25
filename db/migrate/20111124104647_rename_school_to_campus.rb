class RenameSchoolToCampus < ActiveRecord::Migration
  def up
    rename_table :schools, :campus
  end

  def down
    rename_table :campus, :schools
  end
end
