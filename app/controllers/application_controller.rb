class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_current_profile
  # before_filter :prepare_for_mobile
   include ApplicationHelper
  def search_participants
		if params[:school_id] && !params[:school_id].empty?
		search_text =  "#{params[:search_text]}%"
		valueFind=false
      if (is_a_valid_email(search_text))

        @user = User.find(:all, :conditions => ["email = ?", params[:search_text]])
        if !@user.empty?
          @peoples = Profile.find(:all, :conditions => ["user_id != ? AND school_id = ? AND user_id = ?", current_user.id, params[:school_id], @user.first.id ])
          if !@peoples.empty?
            valueFind=true
          else
            render :text=> "you cant add yourself"
          end
        else
          render :partial=>"shared/send_email", :locals=>{:search_text=>"#{params[:search_text]}"}	
        end
      else
        @peoples = Profile.find(:all, :conditions => ["user_id != ? AND school_id = ? AND (name LIKE ? OR full_name LIKE ?)", current_user.id, params[:school_id],search_text,search_text])
        if !@peoples.empty?
        valueFind=true
        else
        render :text=> "No match found"
        end
      end
      if valueFind
        render :partial=>"shared/participant_list", :locals=>{:peoples=>@peoples, :mode=>"result" }
      end
    else
      render :text=> "Error: Parameters missing !!"
    end
  end
  
  private
  
  def set_current_profile()
    if current_user
      profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      user_session[:profile_id] = profile.id
      user_session[:profile_name] = profile.full_name
      user_session[:profile_major] = profile.major.name if profile.major
      user_session[:profile_school] = profile.school.code if profile.school
      user_session[:vault] = profile.school.vaults[0].folder if profile.school
    end
  end
  
  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end
  
  # def set_aws_vault(vault)
  #   ENV['S3_KEY']  = vault.account
  #   ENV['S3_SECR'] = vault.secret
  #   ENV['S3_BUCK'] = vault.folder
  # end
  
end
