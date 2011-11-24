class ChangeSchoolIdToCampusId < ActiveRecord::Migration
  def up
    rename_column :profiles, :school_id, :campus_id
    rename_column :access_codes, :school_id, :campus_id
  end

  def down
  end
end
