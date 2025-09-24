class ChangeCampusIdToSchoolId < ActiveRecord::Migration[4.2]
  def up
    rename_column :profiles, :campus_id, :school_id
    rename_column :access_codes, :campus_id, :school_id
    rename_column :categories, :campus_id, :school_id
    rename_column :courses, :campus_id, :school_id
    rename_column :departments, :campus_id, :school_id
    rename_column :outcome_grades, :campus_id, :school_id
    rename_column :tasks, :campus_id, :school_id
    rename_column :task_grades, :campus_id, :school_id
    rename_column :quests, :campus_id, :school_id
    add_column :outcomes, :school_id, :integer
  end

  def down
    rename_column :profiles, :school_id, :campus_id
    rename_column :access_codes, :school_id, :campus_id
    rename_column :categories, :school_id, :campus_id
    rename_column :courses, :school_id, :campus_id
    rename_column :departments, :school_id, :campus_id
    rename_column :outcome_grades, :school_id, :campus_id
    rename_column :tasks, :school_id, :campus_id
    rename_column :task_grades, :school_id, :campus_id
    rename_column :quests, :school_id, :campus_id
    remove_column :outcomes, :school_id
  end
end
