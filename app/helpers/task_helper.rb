module TaskHelper

  def outcome_associate(outcome_id, task_id)
    if outcome_id
      outcome_task = OutcomeTask.find(:first, :conditions=>["outcome_id = ? AND task_id = ?", outcome_id, task_id])
      if outcome_task
        return true
      end
    end
    return false
  end
  
  def member_associate(member_id, task_id)
    if member_id
      participant = TaskParticipant.find(:first, 
        :conditions => ["profile_id = ? AND task_id = ? AND profile_type = ? ", member_id, task_id, Task.profile_type_member])
      if participant
        return true
      end
    end
    return false
  end
  
  
  def show_date_format(the_date)
     return the_date.strftime('%d/%m/%Y')
  end
end
