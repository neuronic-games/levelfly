class CreateAvatarBadges < ActiveRecord::Migration[4.2]
  def change
    create_table :avatar_badges do |t|
      t.integer :avatar_id
      t.integer :badge_id

      t.timestamps
    end
  end
end
