class SessionsController < Devise::SessionsController
  before_filter :identify_school, :only => :new

  private
  
  def identify_school
    default_school = School.find_by_handle("bmcc")
    school = School.find_by_handle(params[:slug])
    session[:school_id] = school ? school.id : default_school.id
    raise ActionController::RoutingError.new('Page Not Found') if params[:slug] and !school
  end
  
end