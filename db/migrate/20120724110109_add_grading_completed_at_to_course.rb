class AddGradingCompletedAtToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :grading_completed_at, :datetime
  end
end
