class UserMailer < ActionMailer::Base
  default from: "Do Not Reply <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
          reply_to: "Do Not Reply <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>"

  def registration_confirmation(user, sender, course, school, message_id, link, new_user)
    @user = user
    @sender = sender
    @course = course
    @school = school
    @message = message_id
    @link = "#{ENV.fetch('URL', nil)}/system/new_user/?link=#{link}"
    @new_user = new_user
    @subject = "[Levelfly] Your invitation to join #{@course.name} at #{@school.code}"

    mail(from: "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
         to: user,
         subject: @subject)
  end

  def welcome_email(user)
    @resource = user
    mail(from: "Do Not Reply <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
         to: user.email,
         subject: 'Confirmation instructions')
  end

  def school_invite(user, current_profile, target_school = nil)
    @user = user
    @sender = current_profile
    # If target_school is not specified, use the school of the person inviting
    @school = if target_school.nil?
                current_profile.school
              else
                target_school
              end
    hash = Course.hexdigest_to_string(user.id.to_s)
    @link = "#{ENV.fetch('URL', nil)}/system/new_user/?link=#{hash}"
    @subject = "[Levelfly] Your invitation to join #{@school.code}"

    mail(from: "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
         to: user.email,
         subject: @subject)
  end

  def private_message(user, sender, school, message_content)
    @user = user
    @sender = sender
    @school = school
    @message = message_content
    @link = "#{ENV.fetch('URL', nil)}/users/sign_in"
    @subject = "[Levelfly] New message from #{@sender.full_name} at #{@school.code}"

    mail(from: "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
         to: user,
         subject: @subject)
  end

  def wardrobe_unlock_message(user, sender, school, message_content)
    @user = user
    @sender = sender
    @school = school
    @message = message_content
    @link = "#{ENV.fetch('URL', nil)}/users/sign_in"
    @subject = '[Levelfly] You just leveled up!'

    mail(from: "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
         to: user,
         subject: @subject)
  end

  def course_private_message(user, sender, school, course, msg_content)
    @user = user
    @sender = sender
    @school = school
    @message = msg_content
    @course = course
    @subject = "[Levelfly] #{@sender.full_name} at #{@school.code} has sent you a message regarding #{@course.code_section}"
    @link = "#{ENV.fetch('URL', nil)}/users/sign_in"
    mail(from: "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
         to: @user,
         subject: @subject)
  end

  def new_badge(receiver, sender, school, course, badge_name)
    @receiver = receiver
    email = receiver.user.email
    @sender = sender
    @school = school
    @badge_name = badge_name
    @course = course
    @link = "#{ENV.fetch('URL', nil)}/users/sign_in"
    @subject = '[Levelfly] You earned a new badge!'

    mail(from: "#{@sender.full_name} (Do Not Reply) <donotreply@#{ENV.fetch('SMTP_DOMAIN', nil)}>",
         to: email,
         subject: @subject)
  end

  def self.thready
    Thread.new do
      yield
      ActiveRecord::Base.connection.close
    end
  end
end
