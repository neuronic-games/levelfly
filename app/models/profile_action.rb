class ProfileAction < ActiveRecord::Base

  def self.last_action(profile_id)
    url = nil
    controller = nil
    pa = ProfileAction.find(:first, :conditions =>["profile_id = ? and action_type = 'last'",profile_id])
      if pa and !pa.nil?
        action = ProfileAction.find(:first, :conditions =>["profile_id = ? and action_type = ?",profile_id, pa.action_param])
        url = "/#{pa.action_param}/"
        if action and !action.nil?
           url = url + "show/#{action.action_param}"
          if action.action_type = 'course'
            course = Course.find(action.action_param) 
            if course
              url = url+"?section_type=#{course.parent_type}"
            end
          end
        end
      end
    return url  
  end
end
