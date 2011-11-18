class RenameObjectProfileToParticipant < ActiveRecord::Migration
  def change
    rename_table :object_profiles, :participants
  end 
end
