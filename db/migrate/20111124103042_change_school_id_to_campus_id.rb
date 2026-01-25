class ChangeSchoolIdToCampusId < ActiveRecord::Migration[4.2]
  def up
    rename_column :profiles, :school_id, :campus_id
    rename_column :access_codes, :school_id, :campus_id
  end

  def down
    rename_column :profiles, :campus_id, :school_id
    rename_column :access_codes, :campus_id, :school_id
  end
end
