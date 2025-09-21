module TaskHelper
  def outcome_associate(outcome_id, task_id)
    if outcome_id
      outcome_task = OutcomeTask.where(['outcome_id = ? AND task_id = ?', outcome_id, task_id]).first
      return true if outcome_task
    end
    false
  end

  def member_associate(member_id, task_id)
    if member_id
      participant = TaskParticipant.where(['profile_id = ? AND task_id = ? AND profile_type = ? ', member_id, task_id,
                                           Task.profile_type_member]).first
      return true if participant
    end
    false
  end

  def show_date_format(the_date)
    the_date.strftime('%d/%m/%Y')
  end

  def complete_date(profile_id, task_id)
    if profile_id
      participant = TaskParticipant.where(['profile_id = ? AND task_id = ? AND profile_type = ? ', profile_id, task_id,
                                           Task.profile_type_member]).first
      if participant
        if participant.complete_date.nil?
          return 'NOT COMPLETED'
        else
          return show_date_format(participant.complete_date)
        end
      end
    end
    nil
  end

  def member_points(member_id, task_id)
    if member_id && !member_id.nil?
      task_grade = TaskGrade.where(['profile_id = ? AND task_id = ? ', member_id, task_id]).first
      return task_grade.points if task_grade && task_grade.points
    end
    false
  end

  def xp_color(points)
    if points <= 25
      '94b958'
    elsif points > 25 and points <= 50
      'db9321'
    elsif points > 50
      'cb2d2d'
    end
  end

  def task_extra_credit(member_id, task_id)
    if member_id
      participant = TaskParticipant.where(['profile_id = ? AND task_id = ?', member_id, task_id]).first
      return participant.extra_credit if participant
    end
    false
  end

  def long_desc(descr)
    if !descr.nil? && (descr.length > 70)
      str = descr.slice(0, 70) + '...'
      return auto_link(str)
    end
    auto_link(descr)
  end

  def long_title(title)
    if !title.nil? && (title.length > 45)
      str = title.slice(0, 45) + '...'
      return str
    end
    title
  end

  def long_task_title(title)
    if !title.nil? && (title.length > 15)
      str = title.slice(0, 15) + '...'
      return str
    end
    title
  end
end
