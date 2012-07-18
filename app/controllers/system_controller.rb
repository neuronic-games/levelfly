class SystemController < ApplicationController
  def alert
    @profile = Profile.find(user_session[:profile_id])
    @profile.record_action('last', 'alert')
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/system/alert"
        else
          render
        end
      end
    end
  end
  
  def new_user
   @user = User.find(:first, :conditions=>["email = ?",params[:email]])
   #sign_in @user
  end
  
  def edit
   @user = User.find(:first, :conditions=>["id = ?",params[:id]])
   # @user.update_attributes(params[:user])
   # redirect_to root_path
   # @user=User.new
   # @user.password=User.reset_password_token
   # @user.reset_password_token= User.reset_password_token 
   # @user.email=params[:user][:email]
   # @user.save
   @user.update_attributes('password',params[:user][:password])
   sign_in @user
   redirect_to root_path
  end
  
end
