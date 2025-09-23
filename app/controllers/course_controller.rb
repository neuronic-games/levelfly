class CourseController < ApplicationController
  layout 'main'
  before_action :authenticate_user!
  require 'digest/sha1'
  before_action :check_role, only: %i[new save]

  def index
    section_type = params[:section_type] || 'C'

    @profile = Profile.where(['user_id = ? and school_id = ?', current_user.id, school.id]).first

    if params[:search_text]
      search_text = "%#{params[:search_text]}%"
      find_render = true
      if section_type == 'C'
        @courses = Course.where([
                                  '(lower(courses.name) LIKE ? OR lower(courses.code) LIKE ?) and parent_type = ? and school_id = ? and removed = ?', search_text.downcase, search_text.downcase, Course.parent_type_course, @profile.school_id, false
                                ])
                         .includes([:participants])

      elsif section_type == 'G'
        @courses = Course.where(['(lower(courses.name) LIKE ? OR lower(courses.code) LIKE ?) and parent_type = ? and school_id = ? and removed = ?',
                                 search_text.downcase, search_text.downcase, Course.parent_type_group, @profile.school_id, false])
      end
    else

      # Check if the user was working on a details page before, and redirect if so
      return if redirect_to_last_action(@profile, 'course', '/course/show')

      if section_type.nil?
        @courses = []
      else
        if section_type == 'C'
          message_ids = MessageViewer.where(['viewer_profile_id = ?',
                                             @profile.id]).select(:message_id).collect(&:message_id)
          @invites = Message.invites('course_invite', @profile.id, message_ids)
          course_list = Course.course_filter(@profile.id, '')
          @courses = course_list.sort # Sort by semester sort rules
        end
        if section_type == 'G'
          message_ids = MessageViewer.where(['viewer_profile_id = ?',
                                             @profile.id]).select(:message_id).collect(&:message_id)
          @invites = Message.invites('group_invite', @profile.id, message_ids)
          @user_group = false
          @courses = Course.all_group(@profile, 'M')
        end
      end
    end
    @profile.record_action('course', section_type)
    @profile.record_action('last', 'course')
    @section_type = section_type
    respond_to do |wants|
      wants.html do
        if request.xhr?
          if find_render
            render partial: '/course/content_list', locals: { section_type: section_type }
          else
            render partial: '/course/list', locals: { section_type: section_type }
          end
        else
          render
        end
      end
    end
  end

  def send_group_invitation
    status = false
    if params[:id] && !params[:id].nil?
      @course = Course.find_by_id(params[:id])
      @profile = Profile.find(user_session[:profile_id])
      @participant =  participant = Participant.where(["target_id = ? AND target_type = 'Course' AND profile_id = ? ",
                                                       params[:id], user_session[:profile_id]]).first
      @owner = Participant.where(["target_id = ? AND target_type = 'Course' AND profile_type ='M'", params[:id]]).first
      unless @participant
        @participant = Participant.new
        @participant.target_id    = params[:id] if params[:id]
        @participant.profile_id   = user_session[:profile_id]
        @participant.target_type  = 'Course' # Change 'Group' to 'Course' because of query include `participants`.`target_type` = 'Course' when load group or course! Change by vaibhav
        @participant.profile_type = @course.join_type == 'A' ? 'S' : 'P'
        if @participant.save
          status = true
          wall_id = Wall.get_wall_id(params[:id], 'Course')
          Feed.create(
            profile_id: user_session[:profile_id],
            wall_id: wall_id
          )
          # @message.content ="Please accept my group invitation (#{@course.code_section})."
          content = "#{@profile.full_name} has requested to become a member of #{@course.name}"
          message_type = 'group_request'
          @message = Message.send_course_request(user_session[:profile_id], @owner.profile_id, wall_id, params[:id],
                                                 'Course', message_type, content)
        end
      end
      render text: { 'status' => status }.to_json
    end
  end

  def group_joinning
    status = false
    if params[:id] && !params[:id].nil?
      @course = Course.find_by_id(params[:id])
      if @course
        @course.join_type = params[:join_type]
        @course.save
        status = true
      end
      render text: { 'status' => status }.to_json
    end
  end

  def group_viewing
    status = false
    if params[:id] && !params[:id].nil?
      @course = Course.find_by_id(params[:id])
      if @course
        @course.visibility_type = params[:visibility_type]
        @course.save
        status = true
      end
      render text: { 'status' => status }.to_json
    end
  end

  def new
    @profile = current_profile
    # TODO: There is a bug in the view that occurs if a blank course is not saved first.
    # We need to make sure that the id is sent back to the view and the view updated with the id.
    @course = Course.create
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render partial: '/course/form', locals: { course_new: true, section_type: params[:section_type] }
        else
          render
        end
      end
    end
  end

  def show
    @course = Course.find_by_id(params[:id])
    @profile = current_profile
    @wall = Wall.where(["parent_id = ? AND parent_type='Course'", @course.id]).first
    @badges = AvatarBadge.where('profile_id = ? and course_id = ?', @profile.id, @course.id).count unless @profile.nil?
    xp = TaskGrade.select('sum(points) as total').where(
      'school_id = ? and course_id = ? and profile_id = ?',
      @profile.school_id, @course.id, @profile.id
    ).group('task_grades.id')
    @course_xp = xp.first.total unless xp.first.nil? else 0

    section_type = %w[Course Group]
    @member_count = Profile.course_participants(@course.id,
                                                section_type).count

    @member = Participant.where([
                                  "participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id, @profile.id
                                ]).first
    @pending_count = Profile.where([
                                     "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('P')", @course.id
                                   ])
                            .includes([:participants])
                            .joins(:participants)
                            .count
    @courseMaster = Profile.where([
                                    "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", @course.id
                                  ])
                           .includes([:participants])
                           .joins([:participants])
                           .first
    @course_owner = Participant.where(["target_id = ? AND profile_type = 'M' AND target_type='Course'",
                                       params[:id]]).first
    # @totaltask = Task.find(:all, :conditions =>["course_id = ?",@course.id])
    @totaltask = @tasks = Task.filter_by(user_session[:profile_id],
                                         @course.id, 'current')
    @groups = Group.where(['course_id = ?', @course.id])
    message_ids = MessageViewer.where(['viewer_profile_id = ?',
                                       @profile.id]).select(:message_id).collect(&:message_id)
    if params[:section_type] == 'C'
      @course_messages = Message.where([
                                         "parent_id = ? AND parent_type = 'C' AND messages.archived = ? AND message_viewers.viewer_profile_id = ?",
                                         @course.id, false, @profile.id
                                       ])
                                .order('starred DESC, post_date DESC')
                                .includes(:message_viewers)
                                .joins(:message_viewers)
                                .limit(200)
    elsif params[:section_type] == 'G'
      if @member.nil?
        @course_messages = Message.where([
                                           "parent_id = ? AND parent_type = 'G' AND archived = ?",
                                           @course.id, false
                                         ]).order('starred DESC, post_date DESC')
                                  .limit(200)
      else
        @course_messages = Message.where([
                                           "parent_id = ? AND parent_type = 'G' AND messages.archived = ? and message_viewers.viewer_profile_id = ?",
                                           @course.id, false, @profile.id
                                         ])
                                  .order('starred DESC, post_date DESC')
                                  .includes(:message_viewers)
                                  .joins(:message_viewers)
                                  .limit(200)
      end
    end

    @profile.record_action('course', @course.id)
    @profile.record_action('last', 'course')
    # ProfileAction.add_action(@profile.id, "/course/show/#{@course.id}?section_type=#{params[:section_type]}")
    session[:controller] = 'course'
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render partial: '/course/form',
                 locals: {
                   course_new: false, section_type: params[:section_type]
                 }
        end
      end
    end
  end

  def save
    @course = if params[:id] && !params[:id].empty?
                Course.find(params[:id])
              else
                # Save a new course
                Course.new
              end

    # There is a bug where a null course get's saved after inviting a new member
    # and then immediately going to the Files tab. This is not the best fix, but
    # it works.
    if params[:course] == 'null'
      image_url = params[:file] ? @course.image.url : ''
      render text: { 'course' => @course, 'image_url' => image_url, 'outcome' => @outcome }.to_json
      return
    end

    logger.info '-------------------------'
    logger.info @course.inspect
    logger.info '-------------------------'
    @course.name = params[:course].slice(0, 64) if params[:course]
    @course.descr = params[:descr] if params[:descr]
    @course.parent_type = params[:section_type] if params[:section_type]
    @course.code = params[:code].upcase if params[:code]
    @course.section = params[:section] if params[:section]
    @course.school_id = params[:school_id] if params[:school_id]
    @course.rating_low = params[:rating_low] if params[:rating_low]
    @course.rating_medium = params[:rating_medium] if params[:rating_medium]
    @course.rating_high = params[:rating_high] if params[:rating_high]
    @course.tasks_low = params[:task_low] if params[:task_low]
    @course.tasks_medium = params[:task_medium] if params[:task_medium]
    @course.tasks_high = params[:task_high] if params[:task_high]
    @course.post_messages = params[:post_messages] if params[:post_messages]
    @course.allow_uploads = params[:allow_uploads] if params[:allow_uploads]
    @course.show_grade = params[:show_grade] if params[:show_grade]
    @course.semester = params[:semester] if params[:semester]
    @course.year = params[:year] if params[:year]

    if params[:file]
      @course.image.destroy if @course.image
      @course.image = params[:file]
    end

    logger.info @course.inspect
    logger.info '-------------------------'

    if @course.save
      # get wall id
      wall_id = Wall.get_wall_id(@course.id, 'Course')
      # Save categories
      if params[:categories] && !params[:categories].empty?
        categories_array = params[:categories]
        loaded_categories_array = params[:percent_value]
        categories_array.each_with_index do |category, i|
          @category = Category.create(
            name: category,
            percent_value: loaded_categories_array[i],
            course_id: @course.id,
            school_id: @course.school_id
          )
        end
      end

      # Save outcomes
      if params[:outcomes] && !params[:outcomes].empty?
        outcomes_array = params[:outcomes]
        outcomes_descs_array = params[:outcomes_descr]
        outcomes_share_array = params[:outcome_share]
        outcomes_array.each_with_index do |outcome, i|
          @outcome = Outcome.create(
            name: outcome,
            descr: outcomes_descs_array[i],
            school_id: @course.school_id,
            shared: outcomes_share_array[i],
            created_by: @course.id
          )
          @course.outcomes << @outcome
        end
      end

      # Participant record for master
      participant = Participant.where(["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id,
                                       user_session[:profile_id]]).first
      unless participant
        @participant = Participant.new
        @participant.target_id = @course.id
        @participant.target_type = 'Course'
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = 'M'
        if @participant.save
          Feed.create(
            profile_id: user_session[:profile_id],
            wall_id: wall_id
          )
        end
      end
      image_url = params[:file] ? @course.image.url : ''
    end
    render text: { 'course' => @course, 'image_url' => image_url, 'outcome' => @outcome }.to_json
  end

  def get_participants
    search_participants
  end

  def add_participant
    status = false
    already_added = false
    new_user = false
    message_type = nil
    content = nil
    resend = false
    email_exist = []
    if params[:email]
      emails = params[:email].split(/[ ,;]+/)
      profiles = []
      users = []

      emails.each do |email|
        next unless email.length > 0

        # Change 'Group' to 'Course' because of query include `participants`.`target_type` = 'Course' when load group or course! Change by vaibhav
        section_type = 'Course'
        @user = User.where(['lower(email) = ?', email.downcase]).first
        if @user
          @profile = Profile.find_by_user_id(@user.id)
        else
          @user, @profile = User.new_user(email, school.id)
          new_user = true
        end
        if @profile
          # temp fix to not allow invite user of different school
          # if @profile && @profile.school == school
          participant_exist = Participant.where(['target_id = ? AND target_type= ? AND profile_id = ?',
                                                 params[:course_id], section_type, @profile.id]).first
          course = Course.find(params[:course_id])
          if participant_exist
            if participant_exist.profile_type == 'P'
              wall_id = Wall.get_wall_id(params[:course_id], 'Course')
              if params[:section_type] == 'G'
                message_type = 'group_invite'
                content = "You are invited to join the group: #{course.name}."
              elsif params[:section_type] == 'C'
                message_type = 'course_invite'
                content = "Please join #{course.name} (#{course.code_section})."
              end
              @message = Message.send_course_request(user_session[:profile_id], @profile.id, wall_id,
                                                     params[:course_id], section_type, message_type, content)
              @message = Message.where(
                profile_id: user_session[:profile_id],
                parent_id: @profile.id,
                parent_type: section_type,
                wall_id: wall_id,
                target_id: params[:course_id],
                target_type: section_type,
                message_type: message_type
              ).first
              send_email(@user, params[:course_id], @message.id, new_user)
              resend = true
            else
              already_added = true
            end
          else
            @participant = Participant.new
            @participant.target_id = params[:course_id]
            @participant.target_type = section_type
            @participant.profile_id = @profile.id
            @participant.profile_type = 'P'
            if @participant.save
              wall_id = Wall.get_wall_id(params[:course_id], 'Course')
              Feed.create(
                profile_id: @profile.id,
                wall_id: wall_id
              )
              # Send a message. It may also send an email.
              if params[:section_type] == 'G'
                message_type = 'group_invite'
                content = "You are invited to join the group: #{course.name}."
              elsif params[:section_type] == 'C'
                message_type = 'course_invite'
                content = "Please join #{course.name} (#{course.code_section})."
              end
              @message = Message.send_course_request(user_session[:profile_id], @profile.id, wall_id,
                                                     params[:course_id], section_type, message_type, content)
              send_email(@user, params[:course_id], @message.id, new_user)
              status = true
            end
          end
          # else
          #   # temp fix to not allow invite user of different school
          #   email_exist.push(@user.email)
        end
        profiles.push @profile
        users.push @user
      end
      # temp fix to not allow invite user of different school
      render text: {
        'status' => status,
        'already_added' => already_added,
        'profiles' => profiles,
        'users' => users,
        'new_user' => new_user,
        'resend' => resend,
        'email_exist' => email_exist
      }.to_json
    end
  end

  def send_email(user, course, message_id, new_user)
    @course = Course.find(course)
    @school = School.find(current_profile.school_id)
    link = "#{user.id}&#{message_id}"
    @link = Course.hexdigest_to_string(link)
    # @link = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('md5'), "123456", link)
    UserMailer.registration_confirmation(user.email, current_profile, @course, @school, message_id, @link,
                                         new_user).deliver
  end

  # Send email to all participants via course group and forum memberlist
  def send_email_to_all_participants
    status = false
    section_type = 'Course' # TO DO : Need to done for forum and groups also
    post_message = params[:post_message] == 'true' if params[:post_message]
    @course = Course.find(params[:id])
    if @course
      @people = Profile.where([
                                "participants.target_id = ? AND participants.target_type= ? AND participants.profile_type in ('S', 'M')", @course.id, section_type
                              ])
                       .includes([:participants])
                       .joins([:participants])

      if post_message and post_message == true
        wall_id = Wall.get_wall_id(params[:id], params[:section_type]) # params[:wall_id]
        @message = Message.new
        @message.profile_id = user_session[:profile_id]
        @message.parent_id = params[:id] # params[:target_id]
        @message.parent_type = params[:section_type]
        @message.content = CGI.unescape(params[:mail_msg]) if params[:mail_msg]
        @message.target_id = params[:id]
        @message.target_type = params[:section_type]
        @message.message_type = params[:message_type] if params[:message_type]
        @message.wall_id = wall_id
        @message.post_date = DateTime.now
        @message.save
        @message_viewer = MessageViewer.add(user_session[:profile_id], @message.id, params[:section_type], params[:id])
        @feed = Feed.where(['profile_id = ? and wall_id = ?', user_session[:profile_id], wall_id]).first
        Feed.create(profile_id: user_session[:profile_id], wall_id: wall_id) if @feed.nil?
      end

      if @people
        @msg_content = CGI.unescape(params[:mail_msg])
        @current_user = Profile.where(['user_id = ?', current_user.id]).first
        # threads = []
        @people.each do |person|
          UserMailer.delay.course_private_message(person.user.email, @current_user, @current_user.school, @course,
                                                  @msg_content)
        end
        # threads.each(&:join)
        status = true
      end
    end
    render text: { status: status }
  end

  def delete_participant
    status = false
    if params[:profile_id] && params[:course_id]
      participant = Participant.where(["target_id = ? AND target_type = 'Course' AND profile_id = ? ",
                                       params[:course_id], params[:profile_id]]).first
      if participant
        participant.delete
        @wall_id = Wall.where(["parent_id = ? and parent_type = 'C'", params[:course_id]]).first
        unless @wall_id.nil?
          @feed = Feed.where(['profile_id = ? and wall_id = ? ', params[:profile_id], @wall_id.id]).first
          @feed.delete unless @feed.nil?
        end
        forum = Course.where(['course_id = ?', params[:course_id]])
        if forum
          forum.each do |forum|
            forum_participant = Participant.where(["target_id = ? AND target_type = 'Course' AND profile_id = ? ",
                                                   forum.id, params[:profile_id]]).first
            next unless forum_participant

            forum_participant.delete
            wall_id = Wall.where(["parent_id = ? and parent_type = 'C'", forum.id]).first
            next if wall_id.nil?

            feed = Feed.where(['profile_id = ? and wall_id = ? ', params[:profile_id], wall_id.id]).first
            feed.delete unless feed.nil?
          end
        end
        task = Task.where(['course_id = ?', params[:course_id]])
        if task
          task.each do |task|
            task_participant = TaskParticipant.where(["task_id = ? AND profile_id = ? AND profile_type = 'M'", task.id,
                                                      params[:profile_id]]).first
            next unless task_participant

            task_participant.delete
            wall_id = Wall.where(["parent_id = ? and parent_type = 'Task'", task.id]).first
            next if wall_id.nil?

            feed = Feed.where(['profile_id = ? and wall_id = ? ', params[:profile_id], wall_id.id]).first
            feed.delete unless feed.nil?
          end
        end
        status = true
        User.delete_pending_user(params[:profile_id])
      end
    end
    render text: { 'status' => status }.to_json
  end

  def remove_course_outcomes
    if params[:outcomes] && !params[:outcomes].nil?
      if Outcome.find(params[:outcomes]).shared == true && !params[:course_id].nil?
        @course = Course.find(params[:course_id])
        @course.outcomes.destroy(params[:outcomes]) if @course
      else
        Outcome.destroy(params[:outcomes])
      end
      render text: { 'status' => 'true' }.to_json
    end
  end

  def remove_course_files
    if params[:files] && !params[:files].nil?
      Attachment.destroy(params[:files])
      render text: { 'status' => 'true' }.to_json
    end
  end

  def share_outcome
    if params[:course_id] and !params[:course_id].nil?
      @outcome = Outcome.find(params[:outcome_id])
      if @outcome
        @outcome.shared = true
        @outcome.save
        render text: { 'status' => 'true' }.to_json
      end
    end
  end

  def update_course_outcomes
    if params[:outcome_id] && !params[:outcome_id].empty?
      outcome = Outcome.find(params[:outcome_id])
      outcome.name = params[:outcome] if params[:outcome] && !params[:outcome].empty?
      outcome.descr = params[:outcome_descr] if params[:outcome_descr] && !params[:outcome_descr].empty?
      outcome.save
    end
    render text: { 'status' => 'true' }.to_json
  end

  def update_course_categories
    if params[:category_id] && !params[:category_id].empty?
      category = Category.find(params[:category_id])
      category.name = params[:category] if params[:category] && !params[:category].empty?
      category.percent_value = params[:category_value] if params[:category_value] && !params[:category_value].empty?
      category.save
    end
    render text: { 'status' => 'true' }.to_json
  end

  def remove_course_categories
    if params[:categories] && !params[:categories].nil?
      category_array = params[:categories].split(',')
      Category.destroy(category_array)
      render text: { 'status' => 'true' }.to_json
    end
  end

  def view_group_setup
    @course = Course.find_by_id(params[:id])
    @member_count = Profile.count(
      :all,
      include: %i[participants user],
      joins: [:participants],
      conditions: [
        "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S') AND users.status != 'D'", @course.id
      ]
    )
    @pending_count = Profile.count(
      :all,
      include: [:participants],
      joins: [:participants],
      conditions: [
        "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('P')", @course.id
      ]
    )
    @courseMaster = Profile.where([
                                    "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", params[:id]
                                  ])
                           .includes([:participants])
                           .joins([:participants])
                           .first
    render partial: '/group/setup', locals: { :@course => @course }
  end

  def show_course
    @course = Course.find(params[:id])
    @files = @course.attachments.order('starred desc,resource_file_name asc')
    @profile = Profile.where(['user_id = ?', current_user.id]).first
    @badges = AvatarBadge.where('profile_id = ? and course_id = ?', @profile.id, @course.id).count unless @profile.nil?
    xp = TaskGrade.select('sum(points) as total').where(
      'school_id = ? and course_id = ? and profile_id = ?',
      @profile.school_id, @course.id, @profile.id
    ).group('task_grades.id')
    @course_xp = xp.first.total unless xp.first.nil? else 0

                                                          section_type = %w[Course Group]
                                                          @peoples = Profile.course_participants(@course.id,
                                                                                                 section_type)
                                                          @member_count = @peoples.length

                                                          @member = Participant.where([
                                                                                        "participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id, @profile.id
                                                                                      ]).first
                                                          @pending_count = Profile.where([
                                                                                           "participants.target_id = ? AND participants.target_type IN ('Course','Group') AND participants.profile_type IN ('P')", @course.id
                                                                                         ])
                                                                                  .includes([:participants])
                                                                                  .joins([:participants])
                                                                                  .count
                                                          @courseMaster = Profile.where([
                                                                                          "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", params[:id]
                                                                                        ])
                                                                                 .includes([:participants])
                                                                                 .joins([:participants])
                                                                                 .first
                                                          @groups = nil
                                                          # FIXME: needed?
                                                          # @groups = Group.find(:all, :conditions=>["course_id = ?",params[:id]])
                                                          enable_forum = false
                                                          @totaltask = @tasks = Task.filter_by(user_session[:profile_id],
                                                                                               @course.id, 'current')
                                                          if params[:section_type] == 'C'
                                                            @course_messages = Message.where([
                                                                                               "parent_id = ? AND parent_type = 'C' AND message_viewers.viewer_profile_id = ?", @course.id, @profile.id
                                                                                             ])
                                                                                      .order('starred DESC, post_date DESC')
                                                                                      .includes([:message_viewers])
                                                                                      .joins([:message_viewers])
                                                          elsif params[:section_type] == 'G'
                                                            if @member.nil?
                                                              @course_messages = Message.where([
                                                                                                 "parent_id = ? AND parent_type = 'G'", @course.id
                                                                                               ])
                                                                                        .order('starred DESC, post_date DESC')
                                                            else
                                                              @course_messages = Message.where([
                                                                                                 "parent_id = ? AND parent_type = 'G' and message_viewers.viewer_profile_id = ?", @course.id, @profile.id
                                                                                               ])
                                                                                        .order('starred DESC, post_date DESC')
                                                                                        .includes([:message_viewers])
                                                                                        .joins([:message_viewers])
                                                            end
                                                          end
                                                          if params[:value] == '3'
                                                            setting = Setting.where([
                                                                                      "target_id = ? and value = 'true' and target_type ='school' and name ='enable_course_forums' ", @course.school_id
                                                                                    ]).first
                                                            if setting and !setting.nil?
                                                              @groups = @course.course_forum(@profile.id)
                                                              enable_forum = true
                                                            end
                                                          end
                                                          # @totaltask = Task.joins(:participants).where(["profile_id =?",user_session[:profile_id]])
                                                          if params[:value] && !params[:value].nil?
                                                            if params[:section_type] == 'G' && params[:value] == '1'
                                                              render partial: '/group/group_wall',
                                                                     locals: {
                                                                       privilege: params[:privilege].present?, game: @course.game
                                                                     }
                                                            elsif params[:value] == '1'
                                                              render partial: '/course/show_course'
                                                            elsif params[:value] == '3'
                                                              render partial: '/course/forum',
                                                                     locals: {
                                                                       :@groups => @groups, :enable_forum => enable_forum
                                                                     }
                                                            elsif params[:value] == '4'
                                                              render partial: '/course/files'
                                                            elsif params[:value] == '5'
                                                              render partial: '/course/stats'
                                                            end
                                                          end
  end

  def view_member
    @course = Course.find_by_id(params[:id])
    # if params[:section_type] == 'G'
    # section_type = 'Group'
    # else
    # section_type = 'Course'
    # end
    # Change 'Group' to 'Course' because of query include `participants`.`target_type` = 'Course' when load groups or courses! Change by vaibhav
    @profile = Profile.find(user_session[:profile_id])
    section_type = 'Course'
    @courseMaster = Profile.where([
                                    "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M' and profile_id = ? ", @course.id, user_session[:profile_id]
                                  ])
                           .includes([:participants])
                           .joins([:participants])
                           .first

    # Only show pending members to the course owner
    if @courseMaster
      @people_pending = Profile
                        .includes(:participants, :user)
                        .references(:participants)
                        .where("participants.target_id = ? AND participants.target_type= ? AND participants.profile_type IN ('P') AND users.status != 'D'", @course.id, section_type)
                        .order(:full_name, 'users.email')
    end
    @peoples = Profile.course_participants(@course.id, section_type)
    # ProfileAction.add_action(@profile.id, "/course/show/#{@course.id}?section_type=#{params[:section_type]}")
    render partial: '/course/member_list', locals: { course: @course }
  end

  def view_setup
    @course = Course.find_by_id(params[:id])
    render partial: '/course/setup', locals: { course: @course }
  end

  def add_file
    school_id = params[:school_id]
    course_id = params[:id]
    if params[:target_type] == 'Course'
      @course = Course.find(params[:id])
    elsif task = Task.find(params[:id])
      @course = task.course
    end
    @profile = Profile.find(params[:profile_id])
    # @vault = Vault.find(:first, :conditions => ["target_id = ? and target_type = 'School' and vault_type = 'AWS S3'", school_id])
    # if @vault
    @attachment = Attachment.new(resource: params[:file], target_type: params[:target_type], target_id: course_id,
                                 school_id: school_id, owner_id: user_session[:profile_id])
    if @attachment.save
      @url = @attachment.resource.url
      puts "#{@url}--#{params[:target_type]}"
    end
    # end
    render partial: '/course/file_list', locals: { a: @attachment }
  end

  def download
    if params[:id] and !params[:id].blank?
      @attachment = Attachment.find(params[:id])
      if @attachment
        render partial: '/course/download_dialog',
               locals: { a: @attachment, request_type: params[:request_type] }
      end

    end
    # upload = Attachment.find(params[:id])
    # send_file upload.resource.url,
    # :filename => upload.resource_file_name,
    # :type => upload.resource_content_type,
    # :disposition => 'attachment'
  end

  def course_stats
    if params[:id] && !params[:id].blank?
      @grade = []
      @points = []
      @badge = []
      @course = Course.find(params[:id])
      @profile = Profile.where(['user_id = ?', current_user.id]).first
      course_ids = Course.where(['course_id = ?', @course.id]).collect(&:id).push(@course.id)
      message_ids = Like.where(['course_id in (?)', course_ids]).select('message_id').collect(&:message_id)
      message_ids = message_ids.uniq
      @likes =


        
Message.where(['id IN (?) and profile_id = ? and archived = ?', message_ids, @profile.id, false]).select('messages.like'), collect(&:like).sum
      @course_grade, oc = CourseGrade.load_grade(@profile.id, @course.id, @profile.school_id)
      unless @course_grade.nil?
        @course_grade.each do |_key, val|
          @grade.push(val)
          letter = GradeType.value_to_letter(val, @profile.school_id) if val
          @grade.push(letter)
        end
      end
      @outcomes = @course.outcomes.order('name')
      unless @outcomes.nil?
        @points, @course_xp = CourseGrade.get_outcomes(@course.id, @outcomes, @profile.school_id, @profile.id)
      end
      unless @profile.nil?
        @badge = AvatarBadge.where(['profile_id = ? and course_id = ?', @profile.id, @course.id]).select('id, badge_id')
        # @task_grade = TaskGrade.where("school_id = ? and course_id = ? and profile_id = ?",@profile.school_id,@course ,@profile.id)
        @course_tasks = Task.sort_tasks(@profile.id, @course.id)
      end
      render partial: '/course/course_stats'
    end
  end

  def top_achivers
    if params[:outcome_id] && !params[:course_id].blank?
      course = Course.find(params[:course_id])
      @profile = Profile.where(['user_id = ?', current_user.id]).first
      @students = Course.get_top_achievers(course.school_id, params[:course_id], params[:outcome_id])
      render partial: '/course/top_achivers'
    end
  end

  def task_outcomes
    if params[:task_id] && !params[:task_id].blank?
      @task_outcomes = Task.find(params[:task_id]).outcomes
      render partial: '/course/task_outcomes'
    end
  end

  def toggle_priority_file
    if params[:id] and !params[:id].blank?
      @att = Attachment.find(params[:id])
      @att.update_attribute('starred', !(@att.starred == true)) unless @att.nil?
      render text: { starred: @att.starred }.to_json
    end
  end

  def toggle_priority_message
    if params[:id] and !params[:id].blank?
      @msg = Message.find(params[:id])
      @msg.toggle_star unless @msg.nil?
      render text: { starred: @msg.starred }.to_json
    end
  end

  def filter
    if params[:filter] && !params[:filter].blank?
      @profile = Profile.where(['user_id = ?', current_user.id]).first
      if params[:section_type] && !params[:section_type].nil?
        if params[:section_type] == 'C'
          course_list = Course.course_filter(@profile.id, params[:filter])
          @courses = course_list.sort # Sort by semester sort rules
        elsif params[:section_type] == 'G'
          @courses = Course.all_group(@profile, params[:filter])
        end
      end
      render partial: '/course/content_list', locals: { section_type: params[:section_type] }
    end
  end

  def set_archive
    unarchive = params[:unarchive]
    if params[:id] && !params[:id].blank?
      @course = Course.find(params[:id])
      if @course

        if unarchive && @course.parent_type != Course.parent_type_forum
          @course.update_attribute('archived', false)
        else
          @course.update_attribute('archived', true)
          @course.update_attribute('removed', true) if @course.parent_type == Course.parent_type_forum
        end

        render json: { status: 'Success' }
      end
    end
  end

  def load_files
    if params[:id] and !params[:id].blank?
      id = params[:id]
      @profile = Profile.find(params[:profile_id])
      @course = Course.find(params[:course_id])

      if id == 'all'
        @files = @course.attachments.order('starred desc,resource_file_name asc')
      else
        @task = Task.find(params[:id])
        @task_owner = @task.task_owner
        # Course owner can see all the files related to the course and their tasks
        # even if the files are uploaded by other participents
        if @profile.id == @task_owner.id
          @files = @task.attachments.order('starred desc,resource_file_name asc')
        # but other users can see only those files which are uploaded by them via tasks
        else
          @files = @task.attachments.where('owner_id IN (?)',
                                           [@profile.id, @task_owner.id]).order('starred desc,resource_file_name asc')
        end
      end
      render partial: '/course/load_files', locals: { files: @files }
    end
  end

  def removed
    status = nil
    if params[:id] and !params[:id].blank?
      @course = Course.find(params[:id])
      @owner = @course.owner
      if @owner and !@owner.nil? and @owner.id == user_session[:profile_id]
        @course.removed = true
        @course.save
        tasks = Task.filter_by(user_session[:profile_id], @course.id, '')
        tasks.each do |task|
          task.update_attribute('archived', true)
        end
        status = true
      else
        participant = Participant.where([
                                          "participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type = 'S'", @course.id, user_session[:profile_id]
                                        ]).first
        participant.delete if participant
        status = true
      end
    end
    render json: { status: status }
  end

  def show_forum
    if params[:id] and !params[:id].blank?
      @course = Course.find(params[:id])
      @profile = Profile.where(['user_id = ?', current_user.id]).first
      @peoples = Profile.where([
                                 "participants.target_id = ? AND participants.target_type IN ('Course','Group') AND participants.profile_type IN ('P', 'S') AND users.status != 'D'", @course.id
                               ])
                        .includes(%i[participants user])
                        .joins([:participants])
      @member = Participant.where([
                                    "participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id, @profile.id
                                  ]).first
      @member_count = @peoples.length
      @courseMaster = @course.owner
      message_ids = MessageViewer.where(['viewer_profile_id = ?',
                                         @profile.id]).select(:message_id).collect(&:message_id)
      @course_messages = Message.where(["parent_id = ? AND parent_type = 'F' and archived = ? and id in (?)", @course.id,
                                        false, message_ids]).order('starred DESC, post_date DESC')
      render partial: '/course/forum_wall'
    end
  end

  def new_forum
    @course = Course.create
    render partial: '/course/forum_setup'
  end

  def save_forum
    @course = if params[:id] && !params[:id].empty?
                Course.find(params[:id])
              else
                Course.new
              end
    @profile = Profile.find(user_session[:profile_id])
    @course.name = params[:name].slice(0, 64) if params[:name]
    @course.descr = params[:descr] if params[:descr]
    @course.parent_type = 'F'
    @course.code = params[:code].upcase if params[:code]
    @course.school_id = @profile.school_id
    @course.course_id = params[:parent_id] if params[:parent_id]
    @course.post_messages = params[:post_messages] if params[:post_messages]
    if params[:file]
      @course.image.destroy if @course.image
      @course.image = params[:file]
    end
    if @course.save
      wall_id = Wall.get_wall_id(@course.id, 'Course')
      participant = Participant.where(["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id,
                                       user_session[:profile_id]]).first
      unless participant
        @participant = Participant.new
        @participant.target_id = @course.id
        @participant.target_type = 'Course'
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = 'M'
        if @participant.save
          Feed.create(
            profile_id: user_session[:profile_id],
            wall_id: wall_id
          )
        end
      end
      @course.join_all(@profile)
      image_url = params[:file] ? @course.image.url : ''
    end
    render json: { course: @course, image_url: image_url }
  end

  def view_forum_setup
    @course = Course.find_by_id(params[:id])
    render partial: '/course/forum_setup'
  end

  def forum_member_unchecked
    status = false
    if params[:course_id] && !params[:course_id].nil?
      @course = Course.find(params[:course_id])
      wall_id = Wall.get_wall_id(@course.id, 'Course')
      if params[:member_id] && !params[:member_id].nil?
        participant = Participant.where(["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id,
                                         params[:member_id]]).first
        if participant
          participant.delete
          status = true
        else
          @participant = Participant.new
          @participant.target_id = @course.id
          @participant.target_type = 'Course'
          @participant.profile_id = params[:member_id]
          @participant.profile_type = 'S'
          if @participant.save
            Feed.create(
              profile_id: params[:member_id],
              wall_id: wall_id
            )
          end
          status = true
        end
      else
        if params[:check_val] == 'false'
          @course.all_members = false
        else
          @course.all_members = true
          course_participants = Participant.where(["target_id = ? AND target_type='Course' AND profile_type = 'S'",
                                                   @course.course_id])
          course_participants.each do |participant|
            forum_participant = Participant.where(["target_id = ? AND target_type='Course' AND profile_id = ?",
                                                   @course.id, participant.profile_id]).first
            next unless forum_participant.nil? and params[:check_val] == 'true'

            @participant = Participant.new
            @participant.target_id = @course.id
            @participant.target_type = 'Course'
            @participant.profile_id = participant.profile_id
            @participant.profile_type = 'S'
            next unless @participant.save

            Feed.create(
              profile_id: participant.profile_id,
              wall_id: wall_id
            )
          end
        end
        @course.save
        status = true
      end
    end
    render text: { 'status' => status }.to_json
  end

  def check_role
    section_type = ''
    if params[:section_type] and !params[:section_type].nil?
      section_type = params[:section_type]
    elsif params[:parent_type] and !params[:parent_type].nil?
      section_type = params[:parent_type]
    end
    render text: '' if Role.check_permission(user_session[:profile_id], section_type) == false
  end

  def duplicate
    if params[:id]
      courseMaster = Profile.where([
                                     "participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", params[:id]
                                   ])
                            .includes([:participants])
                            .joins([:participants])
                            .first
      if course = Course.find(params[:id]) and courseMaster.id == current_profile.id
        course.delay.duplicate({ name_ext: 'COPY' }, current_user)
        render nothing: true, status: 200
      else
        render nothing: true, status: 401
      end
    end
  end

  def export_activity_csv
    return if params[:id].blank?

    course = Course.find(params[:id])

    csv_rows = course.get_activity_csv
    filename = "course-#{course.code}-#{course.section}-#{Date.today.strftime('%Y%m%d')}.csv"
    send_data(csv_rows, type: 'test/csv', filename: filename)
  end
end
