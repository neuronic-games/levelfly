class Setting < ActiveRecord::Base

  def self.cut_off_number
    setting = Setting.find(:first, :conditions=>["target_type ='school' and name ='cut_off_number' "])
    cut_off_number = setting ? setting.value : 20
  end

  def self.add(school_handle, name, value)
    school = School.find_by_handle(school_handle)
    return unless school
    setting = Setting.find(:first, :conditions => {:target_id => school.id, :target_type => "school", :name => name})
    if setting.nil?
      setting = Setting.new
      setting.target_id = school.id
      setting.target_type = 'school'
      setting.name = name
    end
    setting.value = value
    setting.save
    return setting
  end
end
