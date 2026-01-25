class AddAllowMemberToPostMessageToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :post_messages, :boolean, default: true
  end
end
