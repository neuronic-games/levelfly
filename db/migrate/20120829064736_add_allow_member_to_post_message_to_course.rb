class AddAllowMemberToPostMessageToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :post_messages, :boolean, default: true
  end
end
