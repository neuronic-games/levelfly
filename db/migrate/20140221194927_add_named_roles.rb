class AddNamedRoles < ActiveRecord::Migration[4.2]
  def up
    create_table :permissions do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_group = Permission.create(name: 'create_group')
    modify_wardrobe = Permission.create(name: 'modify_wardrobe')
    modify_settings = Permission.create(name: 'modify_settings')
    create_course = Permission.create(name: 'create_course')
    edit_user = Permission.create(name: 'edit_user')
    modify_rewards = Permission.create(name: 'modify_rewards')
    create_task = Permission.create(name: 'create_task')
    edit_grade = Permission.create(name: 'edit_grade')

    create_table :role_names do |t|
      t.string :name, null: false
      t.timestamps
    end

    student = RoleName.create(name: 'Student')
    teacher = RoleName.create(name: 'Teacher')
    school_admin = RoleName.create(name: 'School Admin')
    levelfly_admin = RoleName.create(name: 'Levelfly Admin')

    create_table :permissions_role_names do |t|
      t.integer :permission_id
      t.integer :role_name_id
    end

    student.permissions = [create_group]
    teacher.permissions = student.permissions + [create_course, create_task, edit_grade]
    school_admin.permissions = teacher.permissions + [edit_user]
    levelfly_admin.permissions = school_admin.permissions + [modify_settings, modify_wardrobe, modify_rewards]

    student.save
    teacher.save
    school_admin.save
    levelfly_admin.save

    add_column :profiles, :role_name_id, :integer

    Profile.all.each do |profile|
      roles = Role.where(profile_id: profile.id).map(&:name)

      profile.role_name = if roles.include?('modify_settings')
                            levelfly_admin
                          elsif roles.include?('edit_user')
                            school_admin
                          elsif roles.include?('create_course')
                            teacher
                          else
                            student
                          end

      profile.save
    end
  end

  def down
    drop_table :role_names
    drop_table :permissions
    drop_table :permissions_role_names
    remove_column :profiles, :role_name_id
  end
end
