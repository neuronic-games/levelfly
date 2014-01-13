class Setting < ActiveRecord::Base

  def self.cut_off_number
    setting = Setting.find(:first, :conditions=>["object_type ='school' and name ='cut_off_number' "])
    cut_off_number = setting ? setting.value : 20
  end

  def self.add(school_handle, name, value)
    school = School.find_by_handle(school_handle)
    return unless school
    setting = Setting.find(:first, :conditions => {:object_id => school.id, :object_type => "school", :name => name})
    if setting.nil?
      setting = Setting.new
      setting.object_id = school.id
      setting.object_type = 'school'
      setting.name = name
    end
    setting.value = value
    setting.save
    return setting
  end
end
