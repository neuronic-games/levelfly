class RegistrationsController < Devise::RegistrationsController
  before_filter :identify_school, :only => :new
  def new
    super
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      school_code = school.default_school? ? "DEFAULT" : school.code
      profile = Profile.create_for_user(@user.id,school_code)
      profile.full_name = params[:user][:full_name]
      profile.save
      #set_current_profile()
      sign_in_and_redirect(resource_name, resource)\
    else
      render :action => :new
    end
  end

  def update
    super
  end

  def identify_school
    default_school = School.find_by_handle("bmcc")
    school = School.find_by_handle(params[:slug])
    session[:school_id] = school ? school.id : default_school.id
    raise ActionController::RoutingError.new('Page Not Found') if params[:slug] and !school
  end
  
end 