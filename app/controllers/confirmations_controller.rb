class ConfirmationsController < Devise::ConfirmationsController
  def show
    reconfirmed = current_user && current_user.pending_reconfirmation?
    super

    if reconfirmed
      flash[:notice] = "Your account email has been successfully changed."
      flash[:email_confirmation] = true
    end
  end
end
