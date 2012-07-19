module ApplicationHelper
 
 def is_a_valid_email(email)
  
  r= Regexp.new(/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/)
	if email.scan(r).uniq.length>0
    #if len.length>0
    return true 
	else
    return false
  end
 end
 
 def default_name(id)
  @user = User.find(id)
  if @user
    return @user.email
  end
 end
  
end
