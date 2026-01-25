class AddExtraCreditToTaskParticipant < ActiveRecord::Migration[4.2]
  def change
    add_column :task_participants, :extra_credit, :boolean, default: false
  end
end
