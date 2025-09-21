class AddXpAwardDateToTaskParticipants < ActiveRecord::Migration
  def change
    add_column :task_participants, :xp_award_date, :datetime
  end
end
