class ApplicationController < ActionController::Base
  protect_from_forgery

  # before_filter :prepare_for_mobile

  private

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
  
  def set_aws_vault(vault)
    ENV['S3_KEY']  = vault.account
    ENV['S3_SECR'] = vault.secret
    ENV['S3_BUCK'] = vault.folder
  end
  
end
