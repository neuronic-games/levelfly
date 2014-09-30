module Devise::Models::Confirmable
  # Override Devise's own method. This one is called only on user creation, not on subsequent email modifications.
  def send_on_create_confirmation_instructions
    UserMailer.welcome_email(self).deliver
  end
end
