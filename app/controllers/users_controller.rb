class UsersController < ApplicationController
 layout 'main'
 before_filter :authenticate_user!
 before_filter :check_role
 
 def index
    @profile = Profile.find(user_session[:profile_id])
    if params[:search_text]
      search_text =  "#{params[:search_text]}%"
      @users = Profile.find(:all, :include => [:user], :conditions=>["school_id = ? and full_name LIKE ? and user_id is not null and users.status != 'D'",@profile.school_id, search_text])      
    else   
      @users = Profile.find(:all, :include => [:user], :conditions=>["school_id = ? and user_id is not null and users.status != 'D'",@profile.school_id])
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
      @avatar = @profile.avatar.to_json
      if @profile
        @role = Role.where("profile_id = ?", @profile.id)
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
   if params[:id] and !params[:id].blank?
     if params[:id] == "all_active"
       @users = Profile.includes(:user).where("school_id = ? and user_id is not null and users.status != 'D'", @profile.school_id).order("full_name")
     elsif params[:id] == "members_of_courses"
       course_ids = Course.find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null", false, false, "C"], :order => "name").collect(&:id)
       profile_ids = Participant.find(:all, :conditions => ["target_id IN (?)",course_ids]).collect(&:profile_id).uniq
     elsif params[:id] == "members_of_groups"
       course_ids = Course.find(:all, :select => "distinct *", :conditions => ["archived = ? and removed = ? and parent_type = ? and name is not null", false, false, "G"], :order => "name").collect(&:id)
       profile_ids = Participant.find(:all, :conditions => ["target_id IN (?)",course_ids]).collect(&:profile_id).uniq
     else
       profile_ids = Participant.find(:all, :conditions => ["target_id = ?",params[:id]]).collect(&:profile_id).uniq
     end
     @users = Profile.includes(:user).where("school_id = ? and user_id is not null and profiles.id IN (?) and users.status != 'D'", @profile.school_id, profile_ids).order("full_name") unless @users
     @profile.record_action('last', 'users')
     render :partial => "/users/load_users", :locals => {:@users=>@users}
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
    @profile = Profile.find(params[:id])
  else
     @email = User.find(:first, :conditions => ["email = ? ",params[:email]])
     if @email and !@email.nil?
       email_exist = true
     else
      @user, @profile = User.new_user(params[:email],school.id)
     end
  end
  if @profile
     @user = User.find(@profile.user_id) 
      if params[:roles_assign] and !params[:roles_assign].nil?
        asign_role = params[:roles_assign].split(",")
        role_names = params[:roles_name].split(",")
        asign_role.each_with_index do |role,i|
          if role == "false"
            @role = Role.find(:first, :conditions=>["profile_id = ? and name = ?",@profile.id,role_names[i]])
            if @role
              @role.delete
            end
          elsif role == "true"
            @role = Role.find(:first, :conditions=>["profile_id = ? and name = ?",@profile.id,role_names[i]])
            if !@role
              Role.create(:profile_id => @profile.id, :name =>role_names[i])
            end
          end    
        end
      end
      @profile.full_name = params[:name] if params[:name]
      #@user.update_attribute("email",params[:email])
      @user.email = params[:email] if params[:email]
      @user.status = params[:status] if params[:status]
      @user.password = params[:user_password] if params[:user_password]
      @user.save
      @profile.save
      status = true
    end
    render :text => {:status=>status, :email_exist =>email_exist}.to_json  
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
 
end
