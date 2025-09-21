class ProfileAction < ActiveRecord::Base

  def self.last_action(profile_id)
    url = nil
    controller = nil
    pa = ProfileAction.where(["profile_id = ? and action_type = 'last'",profile_id]).first
      if pa and !pa.nil?
      action = ProfileAction.where(["profile_id = ? and action_type = ?",profile_id, pa.action_param]).first
        url = "/#{pa.action_param}/"
        if action and !action.nil?
          if action.action_param == "C" or action.action_param == "G"
            url = url+"?section_type=#{action.action_param}"
          elsif action.action_type == 'message'
            url = url + "friends_only/#{action.action_param}"
          else
            url = url + "show/#{action.action_param}"
            if action.action_type = 'course'
              course = Course.find(action.action_param) 
              if course
                url = url+"?section_type=#{course.parent_type}"
              end
            end
          end
        end
      end
    return url  
  end
end
