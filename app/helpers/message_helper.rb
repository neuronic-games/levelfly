module MessageHelper
  def comment_list(message_id)
    @comment = Message.where(["archived = ? AND parent_id = ? AND parent_type = 'Message'", false, message_id])
                      .order('created_at ASC')
    @comments = @comment.reverse.reverse
    @comments
  end

  def user_like(profile_id, message_id)
    @user_like = Like.where(['profile_id = ? AND message_id = ?', profile_id, message_id]).first
    if @user_like
      true
    else
      false
    end
  end

  def is_friend(target_id, profile_id)
    @friends = Participant.where(["target_id = ? AND profile_id = ? AND profile_type = 'F'", target_id,
                                  profile_id]).first
    if @friends
      true
    else
      false
    end
  end

  def belongs_to_course_message(target_id)
    participant = Participant.where("profile_type='S' AND target_id = ? AND target_type='Course'", target_id).count
    participant > 0
  end

  def is_course_request_pending(target_id, profile_id)
    @course_request = Participant.where(["profile_id = ? AND target_id=? AND target_type='Course'", profile_id,
                                         target_id]).first
    @course_request
  end

  def is_request_pending(parent_id, profile_id)
    @friend_request = Message.where([
                                      "parent_id = ? AND profile_id = ? AND message_type = 'Friend' AND (archived is NULL or archived = ?)", parent_id, profile_id, false
                                    ]).first
    if @friend_request
      true
    else
      false
    end
  end

  def gdt(d)
    if d.blank?
      ''
    else
      d.strftime('%m/%d/%Y %I:%M %p')
    end
  end

  def from_utc(mysql)
    gdt(DateTime.parse(mysql).in_time_zone(Oncapus::Application.config.time_zone))
  end

  def last_message(profile_id, current_user)
    message = Message.where([
                              "(archived is NULL or archived = ?) AND message_type in ('Message') and target_type = 'Profile' and parent_type = 'Profile' and ((profile_id = ? and parent_id = ?) or (profile_id = ? and parent_id = ?))", false, current_user, profile_id, profile_id, current_user
                            ])
                     .order('updated_at DESC')
    return message.updated_at if message

    nil
  end

  def messages_viewed(profile_ids, current_user)
    Message.active.interesting.between(profile_ids, current_user).where(
      message_viewers: {
        archived: false,
        poster_profile_id: profile_ids,
        viewer_profile_id: current_user,
        viewed: false
      }
    )
           .select('distinct message_viewers.poster_profile_id')
           .joins(:message_viewers)
           .map(&:poster_profile_id).map(&:to_i)
  end

  def message_content(text)
    link = text.scan(%r{(https?://([-\w.]+)+(:\d+)?(/([\w/_.]*(\?\S+)?)?)?)})
    if text.scan(%r{(http|https|ftp|ftps)://[a-zA-Z0-9\-.]+\.[a-zA-Z]{2,3}(/\S*)?}).uniq.length > 0
      text = text.tr(link[0][0], "<a href = #{link[0][0]}>#{link[0][0]}</>")
      puts(link[0][0])
    end
    text
  end
end
