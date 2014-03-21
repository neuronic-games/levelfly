class AddDefaultSchoolIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :default_school_id, :integer
  end
end
