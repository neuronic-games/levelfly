class Role < ActiveRecord::Base
  belongs_to :profile
  
  @@create_group = 'create_group'
  cattr_accessor :create_group
  
  @@create_task = 'create_task'
  cattr_accessor :create_task
  
  @@create_course = 'create_course'
  cattr_accessor :create_course
  
  @@edit_grade = 'edit_grade'
  cattr_accessor :edit_grade
  
  @@edit_user = 'edit_user'
  cattr_accessor :edit_user
  
  @@modify_rewards = 'modify_rewards'
  cattr_accessor :modify_rewards
  
  @@modify_wardrobe = 'modify_wardrobe'
  cattr_accessor :modify_wardrobe
  
  @@modify_settings = 'modify_settings'
  cattr_accessor :modify_settings
  
  # def self.set_user_role(profile_id)
  #   user_role = Role.find(:first, :conditions => ["profile_id = ? and (name = ? or name = ?)", profile_id,Role.create_group,Role.create_task])
  #   if user_role.nil?
  #      Role.create(:profile_id => profile_id, :name =>Role.create_group)     
  #   end  
  # end
  
  def self.check_permission(profile_id,type)
    role = Profile.find(profile_id).role_name
    return false if role.nil? or role.permissions.nil? or role.permissions.empty?
    role .permissions.each do |role|
      if (type == "G" and role.name == Role.create_group)
        return true
        break
      elsif(type == "T" and role.name == Role.create_task)
        return true
        break
      elsif(type == "C" and role.name == Role.create_course)
        return true
        break
      elsif(type==Role.edit_grade and role.name == Role.edit_grade)
        return true
        break
      elsif(type==Role.edit_user and role.name == Role.edit_user)
        return true
        break 
      elsif(type==Role.modify_rewards and role.name == Role.modify_rewards)
        return true
        break 
      elsif(type==Role.modify_wardrobe and role.name == Role.modify_wardrobe)
        return true
        break   
       elsif(type==Role.modify_settings and role.name == Role.modify_settings)
        return true
        break   
      end
    end
  return false  
  end
  
end
