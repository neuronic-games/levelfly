class UsersController < ApplicationController
 layout 'main'
 before_filter :authenticate_user!
 before_filter :check_role
 
 def index
    @profile = Profile.find(user_session[:profile_id])

    if params[:search_text]
      search_text =  "#{params[:search_text]}%"
      @users = Profile.paginate(
        :include => [:user], 
        :conditions=>["school_id = ? and full_name LIKE ? and user_id is not null and users.status != 'D'", @profile.school_id, search_text],
        :order => 'last_sign_in_at DESC NULLS LAST, full_name',
        :page => 1,
        :per_page => Setting.cut_off_number
      )      
    else   
      @users = Profile.paginate(
        :include => [:user], 
        :conditions=>["school_id = ? and user_id is not null and users.status != 'D'", @profile.school_id],
        :order => 'last_sign_in_at DESC NULLS LAST, full_name',
        :page => 1,
        :per_page => Setting.cut_off_number
      )
    end
    @profile.record_action('last', 'users')
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
      if @profile
        respond_to do |wants|
          wants.html do
            if request.xhr?
              render :partial => "/users/form"
            else
              render
            end
          end
        end
      end
    end
  
 end
 
 def load_users
   @profile = Profile.find(user_session[:profile_id])
   @page = params[:page].to_i

   if params[:id] and !params[:id].blank?
     if params[:id] == "all_active"
       @users = Profile
        .includes(:user)
        .where("school_id = ? and user_id is not null and users.status != 'D'", @profile.school_id)
        .paginate(:page => @page, :per_page => Setting.cut_off_number)
        .order("last_sign_in_at DESC NULLS LAST, full_name")
     elsif params[:id] == "members_of_courses"
       course_ids = Course.find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null", false, false, "C"], :order => "name").collect(&:id)
       profile_ids = Participant.find(:all, :conditions => ["target_id IN (?)",course_ids]).collect(&:profile_id).uniq
     elsif params[:id] == "members_of_groups"
       course_ids = Course.find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null", false, false, "G"], :order => "name").collect(&:id)
       profile_ids = Participant.find(:all, :conditions => ["target_id IN (?)",course_ids]).collect(&:profile_id).uniq
     elsif params[:id] == "organizers_of_courses"
       course_ids = Course.find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null", false, false, "C"], :order => "name").collect(&:id)
       profile_ids = Participant.find(:all, :conditions => ["target_id IN (?) AND profile_type = 'M'", course_ids]).collect(&:profile_id).uniq
     elsif params[:id] == "organizers_of_groups"
       course_ids = Course.find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null", false, false, "G"], :order => "name").collect(&:id)
       profile_ids = Participant.find(:all, :conditions => ["target_id IN (?) AND profile_type = 'M'", course_ids]).collect(&:profile_id).uniq
     elsif params[:id] == "organizers_of_courses_and_groups"
       course_ids = Course.find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and name is not null", false, false], :order => "name").collect(&:id)
       profile_ids = Participant.find(:all, :conditions => ["target_id IN (?) AND profile_type = 'M'", course_ids]).collect(&:profile_id).uniq
     else
       profile_ids = Participant.find(:all, :conditions => ["target_id = ?",params[:id]]).collect(&:profile_id).uniq
     end

     unless @users
       @users = Profile
        .includes(:user)
        .where("school_id = ? and user_id is not null and profiles.id IN (?) and users.status != 'D'", @profile.school_id, profile_ids)
        .paginate(:page => @page, :per_page => Setting.cut_off_number)
        .order("last_sign_in_at DESC NULLS LAST, full_name")
     end

     @profile.record_action('last', 'users')
     render :partial => "/users/load_users", :locals => { :@users => @users, :@page => @page, :@id => params[:id] }
   end
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
      Message.send_school_invitations(@user, current_profile)
      UserMailer.school_invite(@user, current_profile).deliver
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
