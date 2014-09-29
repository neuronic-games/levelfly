class RegistrationsController < Devise::RegistrationsController
  before_filter :identify_school, :only => :new
  def new
    super
  end

  def create
    @user = User.find_by_email(params[:user][:email])
    @school = school
    @role = nil

    if params[:school]
      school_code = params[:school][:code].upcase
    else
      school_code = ''
    end

    if @user && !@user.confirmed?
      if @user.unconfirmed_email
        @user.send_confirmation_instructions
      else
        @user.regenerate_confirmation_token
        UserMailer.welcome_email(@user).deliver
      end

      flash[:notice] = 'You must confirm your email address before continuing. Your confirmation link has just been emailed to you.'
      return redirect_to new_user_session_url
    end

    if params[:user][:full_name].length == 0
      flash[:notice] = ['Enter your full name.']
      return redirect_to new_registration_path(resource_name)
    end

    if school_code.length > 0
      if @school = School.find_by_teacher_code(school_code)
        @role = RoleName.find_by_name('Teacher')
      else
        unless @school = School.find_by_student_code(school_code)
          flash[:invalid] = 'You have entered an invalid Invite Code.'
          return redirect_to new_registration_path(resource_name)
        end
      end
    else
      unless @user || params[:evaluate_confirm]
        flash[:invalid] = 'The email address you entered is not registered with Levelfly.'
        return redirect_to new_registration_path(resource_name)
      end
    end
    if @user
      unless @user.valid_password? params[:user][:password]
        flash[:notice] = ["An account with this email already exists. Enter the correct password or click \"Forgot your password?\" above."]
        return redirect_to new_registration_path(resource_name)
      end
    else
      @user = User.new(params[:user])
    end
    @user.default_school = @school
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
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! USER IS NOT SAVED'
      puts @user.inspect
      puts @user.errors.inspect
      puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      flash[:notice] = resource.errors.full_messages.uniq
      redirect_to new_registration_path(resource_name)
    end
  end

  def update
    super
  end

  def identify_school
    default_school = School.find_by_handle("demo")
    session[:school_id] = default_school.id
  end

end
