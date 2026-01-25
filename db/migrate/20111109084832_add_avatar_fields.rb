class AddAvatarFields < ActiveRecord::Migration[4.2]
  def up
    change_table :avatars do |t|
      t.string :eyes, limit: 64
      t.string :nose, limit: 64
      t.string :mouth, limit: 64
    end
  end

  def down
    remove_column 'avatars', :eyes
    remove_column 'avatars', :nose
    remove_column 'avatars', :mouth
  end
end
