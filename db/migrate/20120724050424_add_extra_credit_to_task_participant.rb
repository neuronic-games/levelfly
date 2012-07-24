class AddExtraCreditToTaskParticipant < ActiveRecord::Migration
  def change
    add_column :task_participants, :extra_credit, :boolean, :default => false
  end
end
