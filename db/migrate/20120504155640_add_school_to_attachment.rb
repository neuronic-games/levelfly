class AddSchoolToAttachment < ActiveRecord::Migration[4.2]
  def up
    add_column :attachments, :school_id, :integer
  end

  def down
    remove_column :attachments, :school_id
  end
end
