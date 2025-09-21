class AddShowOutcomesToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :show_outcomes, :boolean, default: true
    add_column :tasks, :include_task_grade, :boolean, default: true
    add_column :tasks, :grading_complete_date, :datetime
  end
end
