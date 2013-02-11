class SessionsController < Devise::SessionsController
  before_filter :identify_school, :only => :new

  private
  
  def identify_school
    default_school = School.find_by_handle("bmcc")
    session[:school_id] = default_school.id
    
    school = School.find_by_handle(params[:slug])
    if school
      # School.default_vault = school.vault  # TODO: I don't think this line works
      session[:school_id] = school.id
    end
    
    raise ActionController::RoutingError.new('Page Not Found') if params[:slug] and !school
  end
  
end