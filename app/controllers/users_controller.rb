class UsersController < ApplicationController
  layout 'main'
  before_action :authenticate_user!
  before_action :check_role

  def index
    @profile = Profile.find(user_session[:profile_id])
    school_id = @profile.school_id

    if params[:search_text]
      search_text = "#{params[:search_text]}%"
      @users = Profile.includes(:user).where("profiles.school_id = ? and profiles.full_name iLIKE ? and profiles.user_id is not null and users.status != 'D' and users.sign_in_count > 0", school_id, search_text).paginate(
        page: 1, per_page: Setting.cut_off_number
      ).order('users.last_sign_in_at DESC NULLS LAST, profiles.full_name')
    else
      @users = Profile.includes(:user).where("profiles.school_id = ? and profiles.user_id is not null and users.status != 'D' and users.sign_in_count > 0", school_id).paginate(
        page: 1, per_page: Setting.cut_off_number
      ).order('users.last_sign_in_at DESC NULLS LAST, profiles.full_name')
    end
    @profile.record_action('last', 'users')

    # @courses          = Course.all_courses_by_school(school_id)
    # @archived_courses = Course.all_archived_courses_by_school(school_id)
    @groups = Course.all_groups_by_school(school_id)

    # @courses = @courses + @archived_courses

    seasons = Course.pluck(:semester).compact.uniq
    years_range = Course.pluck(:year).compact.uniq.sort.reverse

    year_ranges = []
    years_range.each do |yr|
      year_ranges << ('All' + ' ' + yr.to_s)
      seasons.each do |s|
        year_ranges << (s + ' ' + yr.to_s)
      end
    end

    # years_from = @courses.map{|x| x.created_at.strftime('%Y')}.try(:uniq).try(:sort).try(:reverse)
    # year_ranges = []
    # years_from.each do |yf|
    #   year_ranges << "All " + yf
    #   year_ranges << "Fall " + yf
    #   year_ranges << "Summer-I " + yf
    #   year_ranges << "Summer-I " + yf
    #   year_ranges << "Spring " + yf
    #   year_ranges << "Winter " + yf
    # end

    respond_to do |wants|
      wants.html do
        if request.xhr?
          render partial: '/users/list', locals: { year_ranges: year_ranges }
        else
          render
        end
      end
    end
  end

  def show
    if params[:id] and !params[:id].nil?
      @profile = Profile.find(params[:id])
      @disable_edit = @profile && @profile.has_role(Role.modify_settings) && !current_profile.has_role(Role.modify_settings)
      @avatar = @profile.avatar.to_json
      @all_permissions  = Permission.names
      @user_permissions = @profile.role_name.permissions.names
      if @profile
        respond_to do |wants|
          wants.html do
            if request.xhr?
              render partial: '/users/user'
            else
              puts 'HERE'
              render
            end
          end
        end
      end
    end
  end

  def load_permissions
    if params[:role_name_id]
      @all_permissions  = Permission.names
      @user_permissions = RoleName.find(params[:role_name_id]).permissions.names
      render partial: '/users/permissions'
    end
  end

  def load_users
    course_id = params[:id]
    if course_id.present?
      @course_owner = Course.where(id: course_id).first.try(:owner)
      profile_id = user_session[:profile_id]
      @users = User.find_with_filters(course_id, profile_id, params, params[:page].to_i)
      render partial: '/users/load_users',
             locals: { :@users => @users, :@page => params[:page].to_i, :@id => course_id }
    end
  end

  def load_user_emails
    id = params[:id]
    profile_id = user_session[:profile_id]
    @users = User.find_with_filters(id, profile_id, params)
    @users = @users.map { |p| p.user.email }.compact.uniq
    render json: { users_emails: @users }
  end

  def load_csv
    id = params[:id]
    profile_id = user_session[:profile_id]
    @users = User.find_with_filters(id, profile_id, params)
    send_data User.to_csv(@users),
              type: 'text/csv; charset=iso-8859-1; header=present',
              disposition: 'attachment; filename=users.csv'
  end

  def send_message_to_all_users
    status = false
    if params[:id] and !params[:id].nil?
      id = params[:id]
      profile_id = user_session[:profile_id]
      @people = User.find_with_filters(id, profile_id, params)
      if @people
        @msg_content = CGI.unescape(params[:mail_msg])
        @current_user = Profile.where(['user_id = ?', current_user.id]).first
        @people.each do |people|
          unless people.id == @current_user.id
            Message.save_message(@current_user, people, 'Profile', @msg_content,
                                 'Message')
          end
        end
        status = true
      end
    end
    render text: { 'status' => status }
  end

  def save
    status = false
    email_exist = false
    if params[:id] and !params[:id].blank?
      profile = Profile.find(params[:id])
    else
      @email = User.find_by_email_and_school_id(params[:email], current_profile.school_id)
      if @email and !@email.nil?
        email_exist = true
      else
        @user, profile = User.new_user(params[:email], school.id)
        # start temp fix so 1 user can have only 1 profile
        if profile.nil?
          email_exist = true
        else
          # end temp fix
          Message.send_school_invitations(@user, current_profile)
          UserMailer.school_invite(@user, current_profile).deliver
        end
      end
    end
    if profile
      @user = profile.user
      profile.full_name = params[:name] if params[:name]

      @can_edit = current_profile.has_role(Role.modify_settings) || !profile.has_role(Role.modify_settings)

      if @can_edit
        profile.role_name = RoleName.find(params[:role_name_id]) if params[:role_name_id]
        @user.email = params[:email] if params[:email]
        @user.status = params[:status] if params[:status]
        @user.password = params[:user_password] if params[:user_password]
        @user.skip_reconfirmation!
        @user.save
        profile.save
      end

      status = true
    end

    unless @user.errors[:email].empty?
      status = false
      email_exist = true
    end

    render text: { status: status, email_exist: email_exist }.to_json
  end

  def login_as
    status = nil
    if params[:email] and !params[:email].blank?
      @user = User.find_by_email(params[:email])
      if @user and !@user.nil?
        cookies[:active_admin] = current_user.email
        sign_out current_user
        sign_in @user
        status = true
      else
        status = false
      end
    end
    render text: { status: status }.to_json
  end

  def remove
    status = nil
    if params[:id]
      profile = Profile.find(params[:id])
      timestamp = Time.now.strftime('%d%m%Y')
      @user = profile.user
      check = @user.email.downcase.scan(/del-[0-9]*-/)
      if check.empty?
        @user.skip_reconfirmation!
        @user.status = 'D'
        # this only allows you to delete 1 user with the same email per day
        @user.email = "DEL-#{timestamp}-#{@user.email}"
      end
      status = true if @user.save
    else
      status = false
    end
    render json: { status: status }
  end

  def check_role
    render text: '' if Role.check_permission(user_session[:profile_id], Role.edit_user) == false
  end

  def new
    render partial: '/users/form'
  end

  def set_invite_codes
    @school = current_profile.school
    student_code = params[:student_code].upcase
    teacher_code = params[:teacher_code].upcase

    if School.where(['id != :id AND (student_code = :code OR teacher_code = :code)',
                     { id: @school.id, code: student_code }]).first
      render json: { status: false, field: 'student_code' }
      return
    end

    if School.where(['id != :id AND (student_code = :code OR teacher_code = :code)',
                     { id: @school.id, code: teacher_code }]).first
      render json: { status: false, field: 'teacher_code' }
      return
    end

    @school.student_code = student_code
    @school.teacher_code = teacher_code

    @school.save

    render json: { status: true }
  end

  def load_filtered_courses
    all_courses = Course.all_courses_by_school(params[:school_id]).map(&:id)
    archived_courses = Course.all_archived_courses_by_school(params[:school_id]).map(&:id).uniq
    @all_course_ids = all_courses + archived_courses
    if params[:course_code] == 'All'
      all_codes = Course.get_courses_by_year_range(params).map(&:code).try(:uniq).try(:compact)
      @courses = Course.where(id: @all_course_ids, code: all_codes)
    else
      @courses = Course.where(id: @all_course_ids, code: params[:course_code])
    end
    @courses = if @courses.present?
                 @courses.map { |c| { id: c.id, name: c.name } }
               else
                 []
               end
    render json: { courses: @courses }
  end

  def load_course_codes
    render json: { courses: Course.get_courses_by_year_range(params).map(&:code).try(:uniq).try(:compact) }
  end
end
