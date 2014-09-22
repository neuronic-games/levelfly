class ChangeSchoolOfDefaultProfile < ActiveRecord::Migration
  def up
    default_profile = Profile.where(code: 'DEFAULT').first
    demo = School.where(handle: 'demo').first
    if default_profile and demo
      default_profile.school_id = demo.id
      default_profile.save
    end
  end

  def down
    default_profile = Profile.where(code: 'DEFAULT').first
    demo = School.where(handle: 'bmcc', code: 'BMCC').first
    if default_profile and demo
      default_profile.school_id = demo.id
      default_profile.save
    end
  end
end
