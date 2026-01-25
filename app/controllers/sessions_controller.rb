class SessionsController < Devise::SessionsController
  # before_action :identify_school, :only => :new
  after_action :active_admin, only: :destroy

  private

  def identify_school
    session[:school_id] = school.id
    session[:slug] = params[:slug] || ''
    school = School.find_by_handle(params[:slug])
    if school
      # School.default_vault = school.vault  # TODO: I don't think this line works
      session[:school_id] = school.id
    end

    raise ActionController::RoutingError, 'Page Not Found' if params[:slug] and !school
  end

  def active_admin
    return unless cookies[:active_admin]

    user = User.find_by_email(cookies.delete(:active_admin))
    sign_in user
  end
end
