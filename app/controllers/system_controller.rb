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
  if params[:link] and !params[:link].nil?
     invitation_link = Course.hexdigest_to_digest(params[:link])
     links = invitation_link.split("&")
     @user = User.find(:first, :conditions=>["email = ?",links[0]])
     @message = links[1]
     if @user.nil?
      redirect_to root_path     
     end
   else
      redirect_to root_path
   end
  end
  
  def edit
    @user = User.find(:first, :conditions=>["id = ?",params[:id]])
    @user.password=params[:user][:password]
      if @user.save
        profile = Profile.find(:first, :conditions=>["user_id = ?",@user.id])
        profile.full_name = params[:user][:full_name]
        profile.save
        message_id = params[:user][:message_id]
        @message = Message.find(message_id)
        if @message
          @course_participant = Participant.where("object_type = ? AND object_id = ? AND profile_id = ? AND profile_type='P'",@message.parent_type,@message.target_id,@message.parent_id).first
          course = Course.find(@message.target_id)
          if @course_participant
            @course_participant.profile_type = 'S'
            @course_participant.save
          end
          tasks = Task.find(:all, :conditions => ["course_id = ? and archived = ? and all_members = ?", @message.target_id, false, true])
          if tasks and !tasks.blank?
            tasks.each do |t|
              wall_id = Wall.get_wall_id(t.id,"Task")
              task_owner = TaskParticipant.find(:first, :conditions => ["task_id = ? AND profile_type='O' and complete_date is null", t.id])
              if task_owner
                @profile = Profile.find(task_owner.profile_id)
                @task_participant = TaskParticipant.new
                @task_participant.profile_id = profile.id
                @task_participant.profile_type = "M"
                @task_participant.status = "A"
                @task_participant.priority = "L"
                @task_participant.task_id = t.id
                if @task_participant.save
                  Feed.create(
                    :profile_id => profile.id,
                    :wall_id => wall_id
                  )
                participant_content = "#{@profile.full_name} assigned you a new task: #{t.name}"   
                Message.send_notification(@profile.id,participant_content,profile.id)    
                end
              end
            end
          end
          forums = Course.find(:all, :conditions => ["course_id = ? and archived = ? and all_members = ?", @message.target_id, false, true])
          if forums and !forums.blank?
            forums.each do |forum|
              wall_id = Wall.get_wall_id(forum.id,"Course")
              @forum_participant = Participant.new
              @forum_participant.object_id = forum.id
              @forum_participant.object_type = "Course"
              @forum_participant.profile_id = profile.id
              @forum_participant.profile_type = "S"
              if @forum_participant.save
                Feed.create(
                  :profile_id => profile.id,
                  :wall_id => wall_id
                )
              end
            end
          end
             # Respond to course messages
         content = "#{profile.full_name} has accepted your invitation to #{course.name}."
         @respont_to_course = Message.respond_to_course_invitation(@message.parent_id,@message.profile_id,@message.target_id,content,@message.parent_type)
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
