class Participant < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :profile

  @@profile_type_master = 'M'
  cattr_accessor :profile_type_master

  @@profile_type_student = 'S'
  cattr_accessor :profile_type_student
  
  # Participant.is_member_of(my_course.class.name, my_course.id, my_profile)
  def self.is_member_of(target_type, target_id, profile_id, profile_type = ['M', 'S'])
    is_participant = false
    
    p = Participant.find(:first, 
      :conditions => ["target_type = ? and target_id = ? and profile_id = ? and profile_type in (?)", 
        target_type, target_id, profile_id, profile_type])

    is_participant = !p.nil?
    
    return is_participant
  end
end
