class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.string :object_type, :limit=>64
      t.integer :object_id
      t.timestamps
    end
  end
end
