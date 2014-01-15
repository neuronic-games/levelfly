class RenameObjectIdAndTypeToTargetIdAndType < ActiveRecord::Migration
  AFFECTED_TABLES = [:attachments, :participants, :rewards, :settings, :vaults]
  
  def up
    AFFECTED_TABLES.each do |table_name|
      rename_column table_name, :object_id, :target_id
      rename_column table_name, :object_type, :target_type    
    end
  end

  def down
    AFFECTED_TABLES.each do |table_name|
      rename_column table_name, :target_id, :object_id
      rename_column table_name, :target_type, :object_type   
    end
  end
end
