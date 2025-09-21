class AddIndicesToMessages < ActiveRecord::Migration
  def change
    add_index(:messages, %i[profile_id parent_id])
    add_index(:message_viewers, %i[poster_profile_id viewer_profile_id],
              name: 'index_message_viewers_on_poster_and_viewer')
  end
end
