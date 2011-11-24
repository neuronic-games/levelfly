class RenameSchoolToCampus < ActiveRecord::Migration
  def up
    rename_table :schools, :campus
  end

  def down
  end
end
