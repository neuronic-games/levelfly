class UsersController < ApplicationController
 layout 'main'
 before_filter :authenticate_user!
 before_filter :check_role

 def index
    @profile = Profile.find(user_session[:profile_id])
    school_id = @profile.school_id

    if params[:search_text]
      search_text =  "#{params[:search_text]}%"

      @users = Profile.includes(:user).where("profiles.school_id = ? and profiles.full_name LIKE ? and profiles.user_id is not null and users.status != 'D'", school_id, search_text).paginate(:page => 1, :per_page => Setting.cut_off_number).order("users.last_sign_in_at DESC NULLS LAST, profiles.full_name")

      # @users = Profile.paginate(
      #   :include => [:user],
      #   :conditions=>["school_id = ? and full_name LIKE ? and user_id is not null and users.status != 'D'", school_id, search_text],
      #   :order => 'last_sign_in_at DESC NULLS LAST, full_name',
      #   :page => 1,
      #   :per_page => Setting.cut_off_number
      # )
    else

      @users = Profile.includes(:user).where("profiles.school_id = ? and profiles.user_id is not null and users.status != 'D'", school_id).paginate(:page => 1, :per_page => Setting.cut_off_number).order("users.last_sign_in_at DESC NULLS LAST, profiles.full_name")

      # @users = Profile.paginate(
      #   :include => [:user],
      #   :conditions=>["school_id = ? and user_id is not null and users.status != 'D'", school_id],
      #   :order => 'last_sign_in_at DESC NULLS LAST, full_name',
      #   :page => 1,
      #   :per_page => Setting.cut_off_number
      # )
    end
    @profile.record_action('last', 'users')

    @courses          = Course.all_courses_by_school(school_id)
    @groups           = Course.all_groups_by_school(school_id)
    @archived_courses = Course.all_archived_courses_by_school(school_id)

    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/users/list"
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
              render :partial => "/users/user"
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
      render :partial => "/users/permissions"
    end
  end

  def load_users
    @page = params[:page].to_i
    if params[:id] and !params[:id].blank?
      @course_owner = Course.where(id: params[:id]).first.try(:owner)

      @users = User.find_with_filters(params[:id], user_session[:profile_id], @page)
      render :partial => "/users/load_users", :locals => { :@users => @users, :@page => @page, :@id => params[:id] }
    end
  end

  def load_user_emails
    @users = User.to_emails(params[:id], user_session[:profile_id])
    render :json => {:users_emails => @users}
  end

 def load_csv
   send_data User.to_csv(params[:id], user_session[:profile_id]),
             :type => 'text/csv; charset=iso-8859-1; header=present',
             :disposition => "attachment; filename=users.csv"
 end

 def send_message_to_all_users
   status = false
   if params[:ids] and !params[:ids].nil?
     @people = Profile.find(:all, :conditions => ["id IN (?) ", params[:ids]])
     if @people
       @msg_content = CGI::unescape(params[:mail_msg])
       @current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
       @people.each do |people|
         Message.save_message(@current_user,people,"Profile",@msg_content,"Message") unless people.id == @current_user.id
       end
       status = true
     end
   end
   render :text => {"status" => status}
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
      @user, profile = User.new_user(params[:email],school.id)
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

  status, email_exist = false, true unless @user.errors[:email].empty?

  render :text => {:status=>status, :email_exist => email_exist}.to_json
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
     render :text => {:status => status}.to_json
 end

 def remove
   status = nil
   if params[:id]
     profile = Profile.find(params[:id])
     timestamp = Time.now.strftime("%d%m%Y")
     @user = profile.user
     check = @user.email.downcase.scan(/del\-[0-9]*\-/)
     unless !check.empty?
       @user.skip_reconfirmation!
       @user.status = "D"
       # this only allows you to delete 1 user with the same email per day
       @user.email = "DEL-#{timestamp}-#{@user.email}"
     end
     if @user.save
       status = true
     end
   else
     status = false
   end
   render :json => {:status => status}
 end

 def check_role
    if Role.check_permission(user_session[:profile_id],Role.edit_user)==false
      render :text=>""
    end
  end

 def new
   render :partial => "/users/form"
 end

  def set_invite_codes
    @school = current_profile.school
    student_code = params[:student_code].upcase
    teacher_code = params[:teacher_code].upcase

    if School.find(:first, :conditions => ['id != :id AND (student_code = :code OR teacher_code = :code)', {:id => @school.id, :code => student_code}])
      render :json => {:status => false, :field => 'student_code'}
      return
    end

    if School.find(:first, :conditions => ['id != :id AND (student_code = :code OR teacher_code = :code)', {:id => @school.id, :code => teacher_code}])
      render :json => {:status => false, :field => 'teacher_code'}
      return
    end

    @school.student_code = student_code
    @school.teacher_code = teacher_code

    @school.save

    render :json => {:status => true}
  end
end
