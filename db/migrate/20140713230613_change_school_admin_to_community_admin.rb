class ChangeSchoolAdminToCommunityAdmin < ActiveRecord::Migration[4.2]
  def up
    @role_name = RoleName.find_by_name('School Admin')
    @role_name.name = 'Community Admin'
    @role_name.save
  end

  def down
    @role_name = RoleName.find_by_name('Community Admin')
    @role_name.name = 'School Admin'
    @role_name.save
  end
end
