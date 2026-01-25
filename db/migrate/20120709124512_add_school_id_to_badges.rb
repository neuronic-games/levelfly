class AddSchoolIdToBadges < ActiveRecord::Migration[4.2]
  def change
    add_column :badges, :school_id, :integer
  end
end
