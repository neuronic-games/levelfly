class UserMailer < ActionMailer::Base
  default :from => "OnCampus Admin <admin@oncampus.com>"
  
  def registration_confirmation(user,sender,course,school)
    @user = user
    @sender = sender
    @course = course
    @school = school
    subject     "You have been invited to join #{@course.name} by #{@sender.full_name} at #{@school.code}"
    recipients  user
    sent_on     Time.now
    mail( :to => user, 
          :subject => "You have been invited to join #{@course.name} by #{@sender.full_name} at #{@school.code}")
  end
end