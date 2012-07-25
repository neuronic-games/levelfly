class CreateMessageViewers < ActiveRecord::Migration
  def change
    create_table :message_viewers do |t|
      t.integer     :message_id
      t.integer     :poster_profile_id
      t.integer     :viewer_profile_id
      t.boolean     :archived, :default => false
      t.timestamps
    end
  end
end
