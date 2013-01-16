class UserMailer < ActionMailer::Base
  default :from => "Do Not Reply <donotreply@<%= Oncapus::Application.config.action_mailer.default_url_options[:host] %>>"
  
  def registration_confirmation(user,sender,course,school,message_id,link,new_user)
    @user = user
    @sender = sender
    @course = course
    @school = school
    @message = message_id
    @link = link
    @new_user = new_user
    subject     "You have been invited to join #{@course.name} by #{@sender.full_name} at #{@school.code}"
    recipients  user
    sent_on     Time.now
    mail( :to => user, 
          :subject => "You have been invited to join #{@course.name} by #{@sender.full_name} at #{@school.code}")
  end
end