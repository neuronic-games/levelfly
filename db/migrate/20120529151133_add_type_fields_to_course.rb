class AddTypeFieldsToCourse < ActiveRecord::Migration
  def change
    add_column :courses, :visibility_type, :string, limit: 1, default: 'A'  # All
    add_column :courses, :join_type, :string, limit: 1, default: 'I'  # Invite
  end
end
