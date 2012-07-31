class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      profile = Profile.create_for_user(@user.id)
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
end 