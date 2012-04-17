class UserMailer < ActionMailer::Base
  default :from => "harshitatiwari@cdnsol.com"
  
  def registration_confirmation(user)
    #@user = user
    mail(:to => user, :subject => "Registered", :message => "Welcome  to cdnsol com")
  end
end
