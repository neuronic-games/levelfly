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
      participant = Participant.find(:first, :conditions=>["object_type = 'Task' AND profile_id = ? AND object_id = ? AND profile_type != 'D' ", member_id, task_id])
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
