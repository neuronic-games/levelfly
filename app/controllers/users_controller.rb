class UsersController < ApplicationController
 layout 'main'
 before_filter :authenticate_user!
 before_filter :check_role
 
 def index
    @profile = Profile.find(user_session[:profile_id])
    if params[:search_text]
      search_text =  "#{params[:search_text]}%"
      @users = Profile.find(:all, :conditions=>["school_id = ? and full_name LIKE ? and user_id is not null",@profile.school_id, search_text])      
    else   
      @users = Profile.where("school_id = ? and user_id is not null", @profile.school_id)
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
 
 def save
  status = false
  email_exist = false
  if params[:id] and !params[:id].blank?
    @profile = Profile.find(params[:id])
  else
     @email = User.find(:all, :conditions => ["email = ? ",params[:email]])
     if @email.count>0
       email_exist = true
     else
      @user, @profile = User.new_user(params[:email])
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
      @user.password = params[:user_password] if params[:user_password]
      @user.save
      @profile.save
      status = true
    end
    render :text => {:status=>status, :email_exist =>email_exist}.to_json  
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
