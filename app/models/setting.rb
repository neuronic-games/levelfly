class Setting < ActiveRecord::Base

  def self.cut_off_number
    setting = Setting.find(:first, :conditions=>["target_type ='school' and name ='cut_off_number' "])
    cut_off_number = setting ? setting.value : 20
  end

end
