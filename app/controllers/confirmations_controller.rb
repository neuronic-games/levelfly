class ConfirmationsController < Devise::ConfirmationsController
  def show
    puts '!!!!!!!!!!!!!!!!'
    u = User.find_by_confirmation_token(params[:confirmation_token])
    reconfirmed = u.pending_reconfirmation? if u

    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      sign_in resource

      if reconfirmed
        flash[:notice] = 'Your account email has been successfully changed.'
        flash[:email_confirmation] = true
      else
        set_flash_message(:notice, :confirmed)
      end

      respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
    end
  end
end
