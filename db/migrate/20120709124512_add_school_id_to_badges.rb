class AddSchoolIdToBadges < ActiveRecord::Migration
  def change
    add_column :badges, :school_id, :integer
  end
end
