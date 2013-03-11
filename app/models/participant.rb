class Participant < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :profile
  
  # Participant.is_member_of(my_course.class.name, my_course.id, my_profile)
  def self.is_member_of(object_type, object_id, profile_id, profile_type = ['M', 'S'])
    is_participant = false
    
    p = Participant.find(:first, 
      :conditions => ["object_type = ? and object_id = ? and profile_id = ? and profile_type in (?)"], 
        object_type, object_id, profile_id, profile_type))

    is_participant = !p.nil?
    
    return is_participant
  end
end
