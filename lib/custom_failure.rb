class CustomFailure < Devise::FailureApp
  def redirect_url
    session[:slug].blank? ? new_user_session_path : new_user_session_path + '/' + session[:slug]
  end

  # You need to override respond to eliminate recall
  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
