class UserMailer < ActionMailer::Base
  default :from => "Do Not Reply <donotreply@#{Oncapus::Application.config.action_mailer.default_url_options[:host]}>"

  def registration_confirmation(user,sender,course,school,message_id,link,new_user)
    @user = user
    @sender = sender
    @course = course
    @school = school
    @message = message_id
    @link = "https://#{Oncapus::Application.config.action_mailer.default_url_options[:host]}/system/new_user/?link=#{link}"
    @new_user = new_user
    @subject = "[CollegeQuest] Your invitation to join #{@course.name} at #{@school.code}"
    recipients  user
    sent_on     Time.now
    mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{Oncapus::Application.config.action_mailer.default_url_options[:host]}>",
          :to => user, 
          :subject => @subject)
  end
  
  def private_message(user,sender,school,message_content)
    @user = user
    @sender = sender
    @school = school
    @message = message_content
    @link = "https://#{Oncapus::Application.config.action_mailer.default_url_options[:host]}/users/sign_in"
    @subject = "[CollegeQuest] #{@sender.full_name} at #{@school.code} has sent you a private message"
    recipients  user
    sent_on     Time.now
    mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{Oncapus::Application.config.action_mailer.default_url_options[:host]}>",
          :to => user, 
          :subject => @subject)
  end
	
  def wardrobe_unlock_message(user,sender,school,message_content)
    @user = user
    @sender = sender
    @school = school
    @message = message_content
    @link = "http://#{Oncapus::Application.config.action_mailer.default_url_options[:host]}/users/sign_in"
    @subject = "[CollegeQuest] Congratulations!"
    recipients  user
    sent_on     Time.now
    mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{Oncapus::Application.config.action_mailer.default_url_options[:host]}>",
          :to => user, 
          :subject => @subject)
  end

	def course_private_message(user, sender, school, course, msg_content)
		@user = user
		@sender = sender
    @school = school
		@message = msg_content
		@course = course
		@subject = "[CollegeQuest] #{@sender.full_name} at #{@school.code} has sent you a message regarding #{@course.code_section}"
    @link = "https://#{Oncapus::Application.config.action_mailer.default_url_options[:host]}/users/sign_in"
		mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{Oncapus::Application.config.action_mailer.default_url_options[:host]}>",
		      :to => @user, 
          :subject => @subject)
	end
end