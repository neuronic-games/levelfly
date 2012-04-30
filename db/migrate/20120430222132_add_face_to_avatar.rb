class AddFaceToAvatar < ActiveRecord::Migration
  def up
    add_column :avatars, :face, :string, :limit=>64
    remove_column :avatars, :eyes
    remove_column :avatars, :nose
    remove_column :avatars, :mouth
    remove_column :avatars, :makeup
  end

  def down
    remove_column :avatars, :face
    add_column :avatars, :eyes, :string, :limit=>64
    add_column :avatars, :nose, :string, :limit=>64
    add_column :avatars, :mouth, :string, :limit=>64
    add_column :avatars, :makeup, :string, :limit=>64
  end
end
