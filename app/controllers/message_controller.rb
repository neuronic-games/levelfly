class MessageController < ApplicationController
  layout 'main'
  before_action :authenticate_user!

  def index
    user_session[:last_check_time] = DateTime.now
    @profile = Profile.find(user_session[:profile_id])
    wall_ids = Feed.where(['profile_id = ?', @profile.id]).select('wall_id').collect(&:wall_id)

    message_ids = MessageViewer.where(['viewer_profile_id = ?', @profile.id]).select(:message_id).collect(&:message_id)

    cut_off_number = Setting.cut_off_number
    if params[:messages_length]
      messages_length = params[:messages_length].to_i
      users_length = params[:users_length].to_i
      messages_limit = params[:load] == 'messages' ? messages_length + cut_off_number.to_i : messages_length
      users_limit = params[:load] == 'users' ? users_length + cut_off_number.to_i : users_length
    else
      messages_limit = cut_off_number.to_i
      users_limit = cut_off_number.to_i
    end

    if params[:search_text]
      # Exclude from search messages, if the course they are in, not a users course anymore
      profile_courses_ids = @profile.participants.select('target_id').where(target_type: 'Course').map(&:target_id)
      not_avail_messages_ids = Message.select('id').where(
        "target_id NOT IN (?) AND (target_type = 'C' OR target_type = 'Course') AND profile_id = (?) AND archived = false", profile_courses_ids, @profile.id
      ).map(&:id)
      message_ids -= not_avail_messages_ids

      search_text =  "%#{params[:search_text]}%"
      @comment_ids = Message.where(
        ["(archived is NULL or archived = ?) AND parent_type = 'Message' AND lower(content) LIKE ? ", false,
         search_text.downcase]
      )
                            .select('parent_id')
                            .collect(&:parent_id)
      conditions = [
        "id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend' AND (lower(content) LIKE ? OR id in (?) or lower(topic) LIKE ? )", message_ids, false, search_text.downcase, @comment_ids, search_text.downcase
      ]
      order = nil
    elsif params[:friend_id]
      conditions = [
        "(archived is NULL or archived = ?) AND profile_id = ? AND message_type ='Message' AND parent_type='Profile' and id in (?)", false, params[:friend_id], message_ids
      ]
      order = nil
    else
      conditions = [
        "(archived is NULL or archived = ?) AND message_type in ('Message') and id in (?) and target_type in ('')", false, message_ids
      ]
      order = 'created_at DESC'
      @school_invites = Message.school_invites(message_ids)
      @friend_requests = Message.where([
                                         "message_type in ('Friend', 'course_invite', 'group_request','group_invite') AND parent_id = ? AND (archived is NULL or archived = ?) and id in(?)", @profile.id, false, message_ids
                                       ])
                                .order('created_at DESC')
      @respont_to_course = Message.respond_to_course(@profile.id, message_ids)
    end

    @messages = Message.where(conditions)
                       .order(order)
                       .limit(messages_limit)
    count = Message.where(conditions).count()
    @show_more_btn = (count > messages_limit)

    @users = @profile.recently_messaged[0..users_limit - 1]
    @show_more_users = @profile.recently_messaged.length > users_limit

    @profile.delete_action
    @profile.record_action('last', 'message')
    session[:controller] = 'message'
    render partial: 'list',
           locals: { friend_id: @friend_id, messages_length: messages_limit,
                     users_length: users_limit }
  end

  def alert_badge
    if params[:id] and !params[:id].nil?
      profile = Profile.find(params[:id])
      viewed = notification_badge(profile)
    end
    render json: { alert_badge: viewed }
  end

  def check_request
    @friend_requests = Message.where([
                                       "message_type in ('Friend', 'course_invite') AND parent_id = ? AND (archived is NULL or archived = ?) AND created_at > ?", user_session[:profile_id], false, user_session[:last_check_time]
                                     ])
    render partial: 'message/friend_request_show', locals: { friend_request: @friend_requests }
    user_session[:last_check_time] = DateTime.now
  end

  def check_messages
    message_ids = MessageViewer.where(['viewer_profile_id = ?', user_session[:profile_id]])
                               .select('message_id')
                               .collect(&:message_id)
    @messages = Message.where([
                                "(archived is NULL or archived = ?) AND message_type in ('Message') and id in (?) and target_type in('C','','G') and created_at > ?", false, message_ids, user_session[:last_check_time]
                              ])
                       .order('created_at DESC')
    render partial: 'message/message_load', locals: { friend_request: @friend_requests }
    user_session[:last_check_time] = DateTime.now
  end

  def save
    if params[:parent_id] && !params[:parent_id].nil?
      wall_id = Wall.get_wall_id(params[:parent_id], params[:parent_type]) # params[:wall_id]
      @message = Message.new
      @message.profile_id = user_session[:profile_id]
      @message.parent_id = params[:parent_id] # params[:target_id]
      @message.parent_type = params[:parent_type]
      @message.content = params[:content]
      @message.target_id = params[:parent_id]
      @message.target_type = params[:parent_type]
      @message.message_type = params[:message_type] if params[:message_type]
      @message.wall_id = wall_id
      @message.post_date = DateTime.now

      Message.transaction do
        if @message.save
          if params[:parent_id] && !params[:parent_id].nil? && %w[C G F].include?(@message.parent_type)
            @courseMaster = Profile.where([
                                            "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", params[:parent_id]
                                          ])
                                   .includes([:participants])
                                   .joins([:participants])
                                   .first
          end
          @message_viewer = MessageViewer.add(user_session[:profile_id], @message.id, params[:parent_type],
                                              params[:parent_id])
          send_if_board_message(@message.id)
          # Message.send_if_board_comment(@message.id)
          Message.send_to_forum(@message.id)
          case params[:parent_type]
          when 'Message'
            @msg = Message.find(params[:parent_id])
            if @msg and @msg.parent_type == 'Profile'
              @msg.touch
              @current_user = Profile.where(['user_id = ?', current_user.id]).first
              @school = @current_user.school
              email = Profile.find(@msg.parent_id).user.email if @current_user.id == @msg.profile_id
              email = @msg.profile.user.email unless @current_user.id == @msg.profile_id
              UserMailer.private_message(email, @current_user, @school, @message.content).deliver
            end
            render partial: 'comments', locals: { comment: @message, course_id: @msg.parent_id }
          when 'Profile'
            email = Profile.find(params[:parent_id]).user.email if params[:parent_id]
            @current_user = Profile.where(['user_id = ?', current_user.id]).first
            @school = @current_user.school
            if params[:message_type] && !params[:message_type].nil?
              message = params[:message_type] == 'Friend' ? 'Friend request sent' : 'Message sent'
              if message == 'Message sent'
                UserMailer.private_message(email, @current_user, @school,
                                           @message.content).deliver
              end
              render text: { 'status' => 'save', 'message' => message }.to_json
            else
              UserMailer.private_message(email, @current_user, @school, @message.content).deliver
              @feed = Feed.where(['profile_id = ? and wall_id = ?', user_session[:profile_id], wall_id]).first
              Feed.create(profile_id: user_session[:profile_id], wall_id: wall_id) if @feed.nil?
              render partial: 'messages', locals: { message: @message }
            end
          else
            @feed = Feed.where(['profile_id = ? and wall_id = ?', user_session[:profile_id], wall_id]).first
            Feed.create(profile_id: user_session[:profile_id], wall_id: wall_id) if @feed.nil?
            render partial: 'messages', locals: { message: @message }
          end
        end
      end
    end
  end

  def like
    if params[:message_id] && !params[:message_id].nil?
      @message = Like.add(params[:message_id], user_session[:profile_id], params[:course_id])
      render text: { 'action' => 'unlike', 'count' => @message.like }.to_json if @message
    end
  end

  def unlike
    if params[:message_id] && !params[:message_id].nil?
      @message = Like.remove(params[:message_id], user_session[:profile_id], params[:course_id])
      render text: { 'action' => 'like', 'count' => @message.like }.to_json if @message
    end
  end

  def add_friend_card
    if params[:profile_id] && !params[:profile_id].nil?
      @profile = Profile.find(params[:profile_id])
      course_id = nil
      @current_user = Profile.where(['user_id = ?', current_user.id]).first
      # @owner = Participant.find(:first,:conditions=>["target_id = ? and profile_id = ? and profile_type= 'M' and target_type = 'Course'",params[:course_id],@current_user.id])
      course_ids = Course.where([
                                  "participants.profile_id = ? and participants.profile_type = 'M' and participants.target_type = 'Course' and parent_type = 'C' and removed = ?",
                                  user_session[:profile_id], false
                                ])
                         .includes([:participants])
                         .joins([:participants])
      @courses = Course.where([
                                "participants.profile_id = ? and participants.target_id in(?) and participants.profile_type = 'S' and participants.target_type = 'Course' and parent_type = 'C'",
                                params[:profile_id], course_ids
                              ])
                       .includes([:participants])
                       .order('courses.id')
                       .joins([:participants])
      if @courses && !@courses.empty?
        course_id = if params[:course_id] && !params[:course_id].nil?
                      params[:course_id]
                    else
                      @courses.first.id
                    end
        @participant = Participant.where([
                                           "target_id = ? and profile_id = ? and target_type = 'Course' and profile_type='S'", course_id, @profile.id
                                         ]).first
      end
      render partial: 'add_friend_card', locals: { profile: @profile }
    end
  end

  def respond_to_course_request
    status = nil
    if params[:message_id] && !params[:message_id].nil?
      @message = Message.find(params[:message_id])
      p_id = Profile.find(user_session[:profile_id])
      if @message
        group_request = false
        action = nil
        content = nil
        if params[:activity] && !params[:activity].nil?
          action = if params[:activity] == 'add'
                     'accepted'
                   else
                     'rejected'
                   end
          course = Course.find(@message.target_id)
          if params[:message_type] == 'course_invite'
            content = "#{p_id.full_name} has #{action} your invitation to #{course.name}."
          elsif params[:message_type] == 'Friend'
            content = "#{p_id.full_name} has #{action} your friend request."
          elsif params[:message_type] == 'group_request'
            content = "#{p_id.full_name} has #{action} your request to join #{course.name}."
          elsif params[:message_type] == 'group_invite'
            content = "#{p_id.full_name} has #{action} your invitation to #{course.name}."
          end
          if params[:message_type] == 'group_request'
            group_request = true
            profile_id = @message.profile_id
          else
            profile_id = @message.parent_id
          end

          @course_participant = Participant.where(
            "target_type = ? AND target_id = ? AND profile_id = ? AND profile_type='P'", params[:section_type], @message.target_id, profile_id
          ).first
          tasks = Task.where(['course_id = ? and archived = ? and all_members = ?', @message.target_id, false, true])
          if tasks and !tasks.blank? && (params[:activity] == 'add')
            tasks.each do |t|
              wall_id = Wall.get_wall_id(t.id, 'Task')
              task_owner = TaskParticipant.where(["task_id = ? AND profile_type='O'", t.id]).first
              task_member = TaskParticipant.where('task_id = ? AND profile_id = ?', t.id, p_id.id).count
              next unless task_owner && task_member == 0

              @profile = Profile.find(task_owner.profile_id)
              @task_participant = TaskParticipant.new
              @task_participant.profile_id = user_session[:profile_id]
              @task_participant.profile_type = 'M'
              @task_participant.status = 'A'
              @task_participant.priority = 'L'
              @task_participant.task_id = t.id
              next unless @task_participant.save

              Feed.create(
                profile_id: user_session[:profile_id],
                wall_id: wall_id
              )
              participant_content = "#{@profile.full_name} assigned you a new task: #{t.name}"
              Message.send_notification(@profile.id, participant_content, user_session[:profile_id])
            end
          end
          forums = Course.where(['course_id = ? and archived = ? and all_members = ?', @message.target_id, false, true])
          if forums and !forums.blank? && (params[:activity] == 'add')
            forums.each do |forum|
              wall_id = Wall.get_wall_id(forum.id, 'Course')
              @forum_participant = Participant.new
              @forum_participant.target_id = forum.id
              @forum_participant.target_type = 'Course'
              @forum_participant.profile_id = user_session[:profile_id]
              @forum_participant.profile_type = 'S'
              next unless @forum_participant.save

              Feed.create(
                profile_id: user_session[:profile_id],
                wall_id: wall_id
              )
            end
          end

          if params[:activity] == 'add'
            if @course_participant
              @course_participant.profile_type = 'S'
              @course_participant.save
            end
            # Notification according to message type
            @respont_to_course = Message.respond_to_course_invitation(@message.parent_id, @message.profile_id,
                                                                      @message.target_id, content, params[:section_type])
            status = "Added to #{course.name} (#{course.code_section})"
          else
            @course_participant.delete if @course_participant
            @respont_to_course = Message.respond_to_course_invitation(@message.parent_id, @message.profile_id,
                                                                      @message.target_id, content, params[:section_type])
            status = 'friend_list'
          end
          wall_id = Wall.get_wall_id(@message.target_id, 'C')
          Feed.create(
            profile_id: @message.parent_id,
            wall_id: wall_id
          )

          messages =  Message.where([
                                      'profile_id = ? and parent_id = ? and parent_type = ? and message_type = ? and target_id = ? and archived = ?', @message.profile_id, @message.parent_id, @message.parent_type, @message.message_type, @message.target_id, false
                                    ])
          message_ids = messages.map(&:id)
          messages.each do |message|
            message.update_attributes(archived: true)
          end
          render json: { status: status, message_ids: message_ids }
        end
      end
    end
  end

  def respond_to_friend_request
    if params[:message_id] && !params[:message_id].nil?
      @message = Message.find(params[:message_id])
      profile = Profile.find(user_session[:profile_id])
      if @message
        already_friend = Participant.where([
                                             "target_id = ? AND profile_id = ? AND target_type = 'User' AND profile_type = 'F'", @message.parent_id, @message.profile_id
                                           ]).first
        if params[:activity] && !params[:activity].nil?
          if params[:activity] == 'add' and !already_friend
            content = "#{profile.full_name} has accepted your friend request."
            @friend_participant = Participant.new
            @friend_participant.target_id = @message.parent_id
            @friend_participant.target_type = 'User'
            @friend_participant.profile_id = @message.profile_id
            @friend_participant.profile_type = 'F'
            if @friend_participant.save
              Feed.create(
                wall_id: @message.wall_id,
                profile_id: @friend_participant.profile_id
              )
              # Participant record for friend
              @participant = Participant.new
              @participant.target_id = @message.profile_id
              @participant.target_type = 'User'
              @participant.profile_id = @message.parent_id
              @participant.profile_type = 'F'
              if @participant.save
                # Feed for friend participant
                Feed.create(
                  wall_id: @message.wall_id,
                  profile_id: @participant.profile_id
                )
              end
              @message.archived = true
              @message.save
              Message.send_notification(profile.id, content, @message.profile_id)
            end
          elsif params[:activity] == 'dntadd'
            content = "#{profile.full_name} has rejected your friend request."
            Message.send_notification(profile.id, content, @message.profile_id)
            @message.archived = true
            @message.save
          end
          render nothing: true
        end
      end
    end
  end

  def unfriend
    status = false
    if params[:profile_id] && ![:profile_id].nil?
      @friend_participant = Participant.where(["target_id = ? AND profile_id = ? AND profile_type = 'F'",
                                               user_session[:profile_id], params[:profile_id]]).first
      if @friend_participant
        @friend_participant.delete
        @participant = Participant.where(["target_id = ? AND profile_id = ? AND profile_type = 'F'",
                                          params[:profile_id], user_session[:profile_id]]).first
        @participant.delete if @participant
        status = true
      end
    end
    render text: { 'status' => status }.to_json
  end

  def add_note
    if params[:parent_id] && !params[:parent_id].nil?
      @note = Note.new
      @note.profile_id = user_session[:profile_id]
      @note.about_object_id = params[:parent_id]
      @note.about_object_type = 'Note'
      @note.content = params[:content]
      render text: { 'status' => 'save' }.to_json if @note.save
    end
  end

  def friend_messages
    if params[:profile_id]
      # @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend'", wall_ids, false])
    end
  end

  def show_all
    wall_ids = Feed.where(['profile_id = ?', user_session[:profile_id]])
                   .select('wall_id')
                   .collect(&:wall_id)
    @messages = Message.where(["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend'",
                               wall_ids, false])
    @friend_requests = Message.where([
                                       "message_type ='Friend' AND parent_id = ? AND (archived is NULL or archived = ?)", user_session[:profile_id], false
                                     ])
    @friend = Participant.where(["target_id = ? AND target_type = 'User' AND profile_type = 'F'",
                                 user_session[:profile_id]])
    render partial: 'list', locals: { limit: @limitAttr }
  end

  def friends_only
    wall_ids = Feed.where(['profile_id = ?', user_session[:profile_id]])
                   .select('wall_id')
                   .collect(&:wall_id)
    message_ids = MessageViewer.where(['viewer_profile_id = ?', user_session[:profile_id]])
                               .select('message_id')
                               .collect(&:message_id)
    profile = Profile.find(user_session[:profile_id])
    cut_off_number = Setting.cut_off_number
    messages_length = params[:messages_length].to_i if params[:messages_length]
    messages_limit = params[:messages_length] ? messages_length + cut_off_number.to_i : cut_off_number.to_i
    @friend = Profile.find(params[:friend_id])
    messages = Message.where(
      [
        "(archived is NULL or archived = ?) AND ((profile_id= ? and  parent_id = ?) or (profile_id = ? and parent_id = ?)) AND message_type ='Message' AND parent_type!='Message' and target_type not in('Notification','Course','Group') and id in(?)", false, params[:friend_id], user_session[:profile_id], user_session[:profile_id], params[:friend_id], message_ids
      ], order: 'created_at DESC'
    )
    @messages = messages[0..messages_limit - 1]
    @show_more_btn = messages.length > @messages.length
    profile.record_action('message', @friend.id)
    profile.record_action('last', 'message')
    if @messages and !@messages.blank?
      @messages.each { |message| message.set_as_viewed(params[:friend_id], user_session[:profile_id]) }
    end
    render partial: 'list',
           locals: { friend_id: params[:friend_id], messages_length: messages_limit, users_length: nil }
  end

  def notes
    if params[:friend_id] && !params[:friend_id].nil?
      @notes = Note.where(["profile_id = ? AND about_object_id = ? AND about_object_type = 'Note' ",
                           user_session[:profile_id], params[:friend_id]])
      render partial: 'list', locals: { friend_id: params[:friend_id] }
    end
  end

  def friends_only_all
    wall_ids = Feed.where(['profile_id = ?', user_session[:profile_id]])
                   .select('wall_id')
                   .collect(&:wall_id)
    @messages = Message.where([
                                "wall_id in (?) AND (archived is NULL or archived = ?) AND profile_id=? AND message_type ='Message' AND parent_type='Profile'", wall_ids, false, params[:friend_id]
                              ])
    render partial: 'list', locals: { limit: @limitAttr }
  end

  def remove_request_message
    if params[:id] && !params[:id].nil?
      delete_notification(params[:id]) unless eval(params[:id]).is_a?(Array)
      eval(params[:id]).each { |id| delete_notification(id) } if eval(params[:id]).is_a?(Array)
      render json: { status: true }
    end
  end

  def confirm
    if params[:id] && !params[:id].nil?
      course_master = params[:course_master_id] if params[:course_master_id]
      @del = false
      @message = Message.find(params[:id])
      if course_master and !course_master.nil? && (course_master.to_i != user_session[:profile_id])
        comments_ids = Message.where(['parent_id = ? AND archived = ?', params[:id], false])
                              .select('profile_id')
                              .distinct
                              .collect(&:profile_id)
        comments_ids.each do |c|
          if c != user_session[:profile_id]
            @del = true
            break
          end
        end

      end
      render partial: 'message/warning_box',
             locals: { :@message_id => @message.id, :@type => params[:message_type], :@delete_all => params[:delete_all],
                       :@del => @del }
    end
  end

  def delete_message
    if params[:id] && !params[:id].nil? && params[:message_friends].nil?
      comments_ids = Message.where(['parent_id = ?', params[:id]])
                            .select('id')
                            .collect(&:id)
      # Message.update_all({:archived => true},["id = ?",params[:id]])
      message = Message.find(params[:id])
      message.update_attributes(archived: true)
      message.send_delete_notification(current_profile)
      Message.update_all({ archived: true }, ['id in (?)', comments_ids])
      if params[:delete_all] and params[:delete_all] == 'delete_all'
        MessageViewer.delete_all(['message_id = ?', params[:id]])
        MessageViewer.delete_all(['message_id in(?)', comments_ids])
      else
        @message_viewer = MessageViewer.where(['viewer_profile_id = ? and message_id = ?', user_session[:profile_id],
                                               params[:id]]).first
        if @message_viewer
          MessageViewer.delete_all(['message_id in(?) and viewer_profile_id = ?', comments_ids,
                                    user_session[:profile_id]])
          @message_viewer.delete
        end
      end
      render json: { status: true }
    elsif params[:id] && !params[:id].nil? && params[:message_friends]
      @message_viewer = MessageViewer.where(['viewer_profile_id = ? and message_id = ?', user_session[:profile_id],
                                             params[:id]]).first
      comments_ids = Message.where(['parent_id = ?', params[:id]])
                            .select('id')
                            .collect(&:id)
      if @message_viewer and @message_viewer.poster_profile_id == user_session[:profile_id]
        # Message.update_all({:archived => true},["id = ?",params[:id]])
        message = Message.find(params[:id])
        message.update_attributes(archived: true)
        message.send_delete_notification_to_friends(current_profile)
        Message.update_all({ archived: true }, ['id in (?)', comments_ids])
        MessageViewer.delete_all(['message_id = ?', params[:id]])
        MessageViewer.delete_all(['message_id in(?)', comments_ids])
      elsif @message_viewer
        @message_viewer.delete
      end
      render json: { status: true }
    end
  end

  def save_topic
    if params[:id] and !params[:id].nil?
      @message = Message.find(params[:id])
      if @message
        @message.topic = params[:content]
        @message.save
        render json: { status: true }
      end
    end
  end

  def read_message
    messages = Message.where(id: params[:message_id])
    messages.each { |m| m.set_as_viewed(params[:friend_id], user_session[:profile_id]) } unless messages.empty?
    render nothing: true
  end

  private

  def delete_notification(message_id)
    @message = MessageViewer.where(['viewer_profile_id = ? and message_id = ?', user_session[:profile_id],
                                    message_id]).first
    @message.delete if @message
  end

  def send_if_board_message(message_id)
    Message.push_board_message(message_id) if Message.board_message?(message_id)
  end
end
