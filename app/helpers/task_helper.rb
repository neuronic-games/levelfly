module TaskHelper

  def outcome_associate(outcome_id, task_id)
    if outcome_id
      outcome_task = OutcomeTask.where(["outcome_id = ? AND task_id = ?", outcome_id, task_id]).first
      if outcome_task
        return true
      end
    end
    return false
  end
  
  def member_associate(member_id, task_id)
    if member_id
      participant = TaskParticipant.where(["profile_id = ? AND task_id = ? AND profile_type = ? ", member_id, task_id, Task.profile_type_member]).first
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
      participant = TaskParticipant.where(["profile_id = ? AND task_id = ? AND profile_type = ? ", profile_id, task_id, Task.profile_type_member]).first
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
    if member_id && !member_id.nil?
      task_grade = TaskGrade.where(["profile_id = ? AND task_id = ? ", member_id, task_id]).first
      if task_grade
        return task_grade.points if task_grade.points
      end
    end
    return false
  end
  
  def xp_color(points)
    if points <= 25
      return "94b958"
    elsif points >25 and points <= 50
      return "db9321"
    elsif points > 50
      return "cb2d2d"
    end
  end
  
  def task_extra_credit(member_id, task_id)
    if member_id
      participant = TaskParticipant.where(["profile_id = ? AND task_id = ?", member_id, task_id]).first
      if participant
        return participant.extra_credit
      end
    end
    return false
  end
  
  def long_desc(descr)
    if !descr.nil?
      if descr.length>70
        str = descr.slice(0,70)+"..."
        return auto_link(str)
      end
    end
    return auto_link(descr)
  end
  
  def long_title(title)
    if !title.nil?
      if title.length>45
        str = title.slice(0,45)+"..."
        return str
      end
    end
    return title
  end
  
   def long_task_title(title)
    if !title.nil?
      if title.length>15
        str = title.slice(0,15) +"..."
        return str
      end
    end
    return title
  end
  
end
