class ChangeSchoolOfDefaultProfile < ActiveRecord::Migration[4.2]
  def up
    default_profile = Profile.where(code: 'DEFAULT').first
    demo = School.where(handle: 'demo').first
    return unless default_profile and demo

    default_profile.school_id = demo.id
    default_profile.save
  end

  def down
    default_profile = Profile.where(code: 'DEFAULT').first
    demo = School.where(handle: 'bmcc', code: 'BMCC').first
    return unless default_profile and demo

    default_profile.school_id = demo.id
    default_profile.save
  end
end
