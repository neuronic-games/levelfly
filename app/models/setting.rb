class Setting < ActiveRecord::Base
  def self.cut_off_number
    setting = Setting.where(["target_type ='school' and name = 'cut_off_number' "]).first
    setting ? setting.value : 20
  end

  def self.add(school_handle, name, value)
    school = School.find_by_handle(school_handle)
    return unless school

    setting = Setting.where({ target_id: school.id, target_type: 'school', name: name }).first
    if setting.nil?
      setting = Setting.new
      setting.target_id = school.id
      setting.target_type = 'school'
      setting.name = name
    end
    setting.value = value
    setting.save
    setting
  end

  def self.default_date_format(date)
    if date.blank?
      ''
    else
      date.strftime('%m-%d-%Y')
    end
  end

  def self.default_date_time_format(date)
    if date.blank?
      ''
    else
      date.strftime('%m-%d-%Y %I:%M %p')
    end
  end
end
