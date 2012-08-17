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
  
  def complete_date(profile_id, task_id)
    if profile_id
      participant = TaskParticipant.find(:first,:conditions => ["profile_id = ? AND task_id = ? AND profile_type = ? ", profile_id, task_id, Task.profile_type_member])
      if participant
        if participant.complete_date == nil  
          return "NOT COMPLETED"
        else
          return show_date_format(participant.complete_date)
        end
     end
    end
    return nil
  end
  
  def member_points(member_id, task_id)
    if member_id
      participant = TaskParticipant.find(:first, 
        :conditions => ["profile_id = ? AND task_id = ? AND xp_award_date is not null ", member_id, task_id])
      if participant
        return true
      end
    end
    return false
  end
  
  def task_extra_credit(member_id, task_id)
    if member_id
      participant = TaskParticipant.find(:first, :conditions => ["profile_id = ? AND task_id = ?", member_id, task_id])
      if participant
        return participant.extra_credit
      end
    end
    return false
  end
  
  def long_desc(descr)
    if !descr.nil?
      if descr.length>100
        str = descr.slice(0,100) +"..."
        return str
      end
    end
    return descr
  end
  
  def long_title(title)
    if !title.nil?
      if title.length>30
        str = title.slice(0,30) +"..."
        return str
      end
    end
    return title
  end
end
