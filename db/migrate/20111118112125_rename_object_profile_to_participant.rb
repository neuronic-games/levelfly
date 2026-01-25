class RenameObjectProfileToParticipant < ActiveRecord::Migration[4.2]
  def change
    rename_table :object_profiles, :participants
  end
end
