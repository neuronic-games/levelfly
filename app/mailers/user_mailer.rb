class UserMailer < ActionMailer::Base
  default :from => "Do Not Reply <donotreply@#{ENV['MAIL_DOMAIN']}>",
          :reply_to => "Do Not Reply <donotreply@#{ENV['MAIL_DOMAIN']}>"

  def registration_confirmation(user,sender,course,school,message_id,link,new_user)
      @user = user
      @sender = sender
      @course = course
      @school = school
      @message = message_id
      @link = "http://#{ENV['URL']}/system/new_user/?link=#{link}"
      @new_user = new_user
      @subject = "[Levelfly] Your invitation to join #{@course.name} at #{@school.code}"

      mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV['MAIL_DOMAIN']}>",
            :to => user,
            :subject => @subject)
  end

  def welcome_email(user)
    @resource = user
    mail( :from => "Do Not Reply <donotreply@#{ENV['MAIL_DOMAIN']}>",
          :to => user.email,
          :subject => "Confirmation instructions")
  end

  def school_invite(user, current_profile)
      @user = user
      @sender = current_profile
      @school = current_profile.school
      hash = Course.hexdigest_to_string("#{user.id}")
      @link = "http://#{ENV['URL']}/system/new_user/?link=#{hash}"
      @subject = "[Levelfly] Your invitation to join #{@school.code}"

      mail(:from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV['MAIL_DOMAIN']}>",
           :to => user.email,
           :subject => @subject)
  end

  def private_message(user,sender,school,message_content)
      @user = user
      @sender = sender
      @school = school
      @message = message_content
      @link = "http://#{ENV['URL']}/users/sign_in"
      @subject = "[Levelfly] New message from #{@sender.full_name} at #{@school.code}"

      mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV['MAIL_DOMAIN']}>",
            :to => user,
            :subject => @subject)
  end

  def wardrobe_unlock_message(user,sender,school,message_content)
      @user = user
      @sender = sender
      @school = school
      @message = message_content
      @link = "http://#{ENV['URL']}/users/sign_in"
      @subject = "[Levelfly] You just leveled up!"

      mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV['MAIL_DOMAIN']}>",
            :to => user,
            :subject => @subject)
  end

  def course_private_message(user, sender, school, course, msg_content)
      @user = user
      @sender = sender
      @school = school
      @message = msg_content
      @course = course
      @subject = "[Levelfly] #{@sender.full_name} at #{@school.code} has sent you a message regarding #{@course.code_section}"
      @link = "http://#{ENV['URL']}/users/sign_in"
      mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV['MAIL_DOMAIN']}>",
            :to => @user,
            :subject => @subject)
  end

  def new_badge(receiver,sender,school,course,badge_name)
      @receiver = receiver
      email = receiver.user.email
      @sender = sender
      @school = school
      @badge_name = badge_name
      @course = course
      @link = "http://#{ENV['URL']}/users/sign_in"
      @subject = "[Levelfly] You earned a new badge!"

      mail( :from => "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV['MAIL_DOMAIN']}>",
            :to => email,
            :subject => @subject)
  end

  private
  def self.thready
    Thread.new do
      yield
      ActiveRecord::Base.connection.close
    end
  end
end
