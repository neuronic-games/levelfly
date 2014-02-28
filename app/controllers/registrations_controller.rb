class RegistrationsController < Devise::RegistrationsController
  before_filter :identify_school, :only => :new
  def new
    super
  end

  def create
    if (@user = User.find_by_email(params[:user][:email])) && !@user.confirmed?
      @user.send_confirmation_instructions
      flash[:notice] = 'You must confirm your account before continuing. Your confirmation link has just been emailed to you.'
      redirect_to new_user_session_url
    else
      @school = school
      @role = nil
      school_code = params[:school][:code].upcase

      if params[:user][:full_name].length == 0
        flash[:notice] = ['Enter your full name.']
        return redirect_to new_registration_path(resource_name)
      end

      if params[:school][:code].length > 0
        if @school = School.find_by_teacher_code(school_code)
          @role = RoleName.find_by_name('Teacher')
        else
          unless @school = School.find_by_student_code(school_code)
            flash[:notice] = ['That school invite code does not exist.']
            return redirect_to new_registration_path(resource_name)
          end
        end
      end

      @user = User.new(params[:user])
      if @user.save
        profile = Profile.create_for_user(@user.id, @school.id)
        profile.full_name = params[:user][:full_name]

        if @role
          profile.role_name = @role
        end

        profile.save
        #set_current_profile()
        sign_in_and_redirect(resource_name, resource)
      else
        flash[:notice] = resource.errors.full_messages.uniq
        redirect_to session[:slug].blank? ? new_registration_path(resource_name) : new_registration_path(resource_name) + "/" + school.handle
      end
    end
  end

  def update
    super
  end

  def identify_school
    default_school = School.find_by_handle("bmcc")
    school = School.find_by_handle(params[:slug])
    session[:slug] = params[:slug] ? params[:slug] : ""
    session[:school_id] = school ? school.id : default_school.id
    raise ActionController::RoutingError.new('Page Not Found') if params[:slug] and !school
  end
  
end 