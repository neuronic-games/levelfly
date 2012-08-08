class UsersController < ApplicationController
 before_filter :authenticate_user!
 before_filter :check_role
 def index
   @profile = Profile.find(user_session[:profile_id])
   @users = Profile.where("school_id = ? and user_id is not null", @profile.school_id)
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
  if params[:id] and !params[:id].nil?
    @profile = Profile.find(params[:id])
    if @profile
      @user = User.find(@profile.user_id) 
      if params[:roles_asign] and !params[:roles_asign].nil?
        asign_role = params[:roles_asign].split(",")
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
      @user.update_attribute("email",params[:email])
      if @profile.save
        render :text=>"save"
      end
    end
  end
 end
 
 def check_role
    if Role.check_permission(user_session[:profile_id],Role.edit_user)==false
      render :text=>""
    end
  end

end
