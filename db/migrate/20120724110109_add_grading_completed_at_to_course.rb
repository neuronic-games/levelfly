class AddGradingCompletedAtToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :grading_completed_at, :datetime
  end
end
