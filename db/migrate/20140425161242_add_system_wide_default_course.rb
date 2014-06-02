class AddSystemWideDefaultCourse < ActiveRecord::Migration
  def up
    @profile = Profile.where(:full_name => 'Neuronic Admin').order('created_at').first
    @no_course = Course.new(:name => 'No Course', :code => '', :school_id => @profile.school_id)
    @no_course.owner = @profile
    @no_course.save
  end

  def down
    @no_course.where(:code => '').destroy_all
  end
end
