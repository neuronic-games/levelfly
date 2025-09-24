class AddXpAwardDateToTaskParticipants < ActiveRecord::Migration[4.2]
  def change
    add_column :task_participants, :xp_award_date, :datetime
  end
end
