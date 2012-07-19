class SystemController < ApplicationController
  def alert
    @profile = Profile.find(user_session[:profile_id])
    @profile.record_action('last', 'alert')
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/system/alert"
        else
          render
        end
      end
    end
  end
  
  def new_user
   @user = User.find(:first, :conditions=>["email = ?",params[:email]])
   @message = params[:message_id]
  end
  
  def edit
    @user = User.find(:first, :conditions=>["id = ?",params[:id]])
    @user.password=params[:user][:password]
      if @user.save
        message_id = params[:user][:message_id]
        @message = Message.find(message_id)
        if @message
          @course_participant = Participant.where("object_type = ? AND object_id = ? AND profile_id = ? AND profile_type='P'",@message.parent_type,@message.target_id,@message.parent_id).first
          if @course_participant
            @course_participant.profile_type = 'S'
            @course_participant.save
          end
             # Respond to course messages
         @respont_to_course = Message.respond_to_course_invitation(@message.parent_id,@message.profile_id,@message.target_id,"Accepted",@message.parent_type)
         @message.archived = true
         @message.save
         wall_id = Wall.get_wall_id(@message.target_id, "C")
         Feed.create(:profile_id => @message.parent_id,:wall_id =>wall_id)
      end
     #@user.update_attributes('password',params[:user][:password])
     sign_in @user
     redirect_to root_path
  end
  end 
  
end
