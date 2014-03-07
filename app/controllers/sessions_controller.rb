class SessionsController < Devise::SessionsController
  before_filter :identify_school, :only => :new
  after_filter :active_admin, :only => :destroy
  
  private
  
  def identify_school
    default_school = School.find_by_handle("demo")
    session[:school_id] = default_school.id
    session[:slug] = params[:slug] ? params[:slug] : ""
    school = School.find_by_handle(params[:slug])
    if school
      # School.default_vault = school.vault  # TODO: I don't think this line works
      session[:school_id] = school.id
    end
    
    raise ActionController::RoutingError.new('Page Not Found') if params[:slug] and !school
  end

  def active_admin
    if cookies[:active_admin]
      user = User.find_by_email(cookies.delete :active_admin)
      sign_in user
    end
  end

end