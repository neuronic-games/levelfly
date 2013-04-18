class MessageController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
 def index
    user_session[:last_check_time] = DateTime.now
    @profile = Profile.find(user_session[:profile_id])
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?", @profile.id]).collect(&:wall_id)
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", @profile.id]).collect(&:message_id)
    if params[:search_text]
      search_text =  "%#{params[:search_text]}%"
      @comment_ids = Message.find(:all,
        :select => "parent_id", 
        :conditions => ["(archived is NULL or archived = ?) AND parent_type = 'Message' AND lower(content) LIKE ? ", false, search_text.downcase]).collect(&:parent_id)
      @messages = Message.find(:all, 
        :conditions => ["id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend' AND (lower(content) LIKE ? OR id in (?) or lower(topic) LIKE ? )", message_ids, false, search_text.downcase, @comment_ids,search_text.downcase])
      
    elsif params[:friend_id]
      @messages = Message.find(:all, :conditions => ["(archived is NULL or archived = ?) AND profile_id = ? AND message_type ='Message' AND parent_type='Profile' and id in (?)", false, params[:friend_id], message_ids])  
    else 
      @messages = Message.find(:all, :conditions => ["(archived is NULL or archived = ?) AND message_type in ('Message') and id in (?) and target_type in('C','','G','F')",false,message_ids], :order => 'created_at DESC')
      
      @friend_requests = Message.find(:all, :conditions=>["message_type in ('Friend', 'course_invite', 'group_request','group_invite') AND parent_id = ? AND (archived is NULL or archived = ?) and id in(?)", @profile.id, false, message_ids],:order => 'created_at DESC')
      
      @respont_to_course = Message.find(:all,:conditions=>["target_type in('Course','Notification') AND message_type = 'Message' AND parent_type='Profile' AND parent_id = ? AND archived = ? and id in(?)", @profile.id,false,message_ids], :order => 'created_at DESC')
    end
    
     recently_messaged = Message.find(:all, :conditions => ["(archived is NULL or archived = ?) AND message_type in ('Message') and id in (?) and target_type = 'Profile' and parent_type = 'Profile' and (profile_id = ? or parent_id = ?)",false,message_ids,user_session[:profile_id],user_session[:profile_id]],:order=>"updated_at desc")
     profile_ids = []
     @users = []
     recently_messaged.each do |r|
       profile_ids.push(r.profile_id)
       profile_ids.push(r.parent_id)
     end
     profile_ids=profile_ids.uniq
     if profile_ids.length>0
        profile_ids.each do |id|
          if id != user_session[:profile_id]
            @user = Profile.find(id)
            @users.push(@user)
          end  
        end
     end
     #friend_id = Participant.find(:all, :select =>"distinct profile_id", :conditions=>["object_id = ? AND object_type = 'User' AND profile_type = 'F'", @profile.id]).collect(&:profile_id)
   
    # if recently_messaged.empty?
      # ids = recently_messaged_by_other
    # else
      # ids = recently_messaged.zip(recently_messaged_by_other).flatten.compact
    # end
    @profile.delete_action
    @profile.record_action('last', 'message')
    session[:controller]="message"
    render :partial => "list",:locals => {:friend_id => @friend_id} 
  end
  
  def alert_badge
    if params[:id] and !params[:id].nil?
      profile = Profile.find(params[:id])
      viewed = notification_badge(profile)
    end
    render :json => {:alert_badge => viewed}
  end
  
  def check_request
    @friend_requests = Message.find(:all, :conditions=>["message_type in ('Friend', 'course_invite') AND parent_id = ? AND (archived is NULL or archived = ?) AND created_at > ?", user_session[:profile_id], false,user_session[:last_check_time]])
    render:partial=>"message/friend_request_show",:locals=>{:friend_request => @friend_requests}
    user_session[:last_check_time] = DateTime.now
  end
  
  def check_messages
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", user_session[:profile_id]]).collect(&:message_id)
    @messages = Message.find(:all, :conditions => ["(archived is NULL or archived = ?) AND message_type in ('Message') and id in (?) and target_type in('C','','G') and created_at > ?",false,message_ids,user_session[:last_check_time]], :order => 'created_at DESC')
    render:partial=>"message/message_load",:locals=>{:friend_request => @friend_requests}
    user_session[:last_check_time] = DateTime.now
  end
  
  
  def save
    if params[:parent_id] && !params[:parent_id].nil?
      wall_id = Wall.get_wall_id(params[:parent_id], params[:parent_type]) #params[:wall_id]
      @message = Message.new
      @message.profile_id = user_session[:profile_id]
      @message.parent_id = params[:parent_id] #params[:target_id]
      @message.parent_type = params[:parent_type] 
      @message.content = params[:content]
      @message.target_id = params[:parent_id]
      @message.target_type = params[:parent_type]
      @message.message_type = params[:message_type] if params[:message_type]
      @message.wall_id = wall_id
      @message.post_date = DateTime.now
     
      if @message.save
        if params[:parent_id] && !params[:parent_id].nil?
          @courseMaster = Profile.find(
            :first, 
            :include => [:participants], 
            :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'M'", params[:parent_id]]
            )
        end
        @message_viewer = MessageViewer.add(user_session[:profile_id],@message.id,params[:parent_type],params[:parent_id])
        case params[:parent_type]
          when "Message"
            @msg = Message.find(params[:parent_id])
            if @msg and @msg.parent_type == "Profile"
              @msg.touch
              @current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
              @school = @current_user.school
              email = Profile.find(@msg.parent_id).user.email if @current_user.id == @msg.profile_id
              email = @msg.profile.user.email unless @current_user.id == @msg.profile_id
              UserMailer.private_message(email,@current_user,@school,@message.content).deliver
            end
            render :partial => "comments", :locals => {:comment => @message,:course_id=>@msg.parent_id}
          when "Profile"
            email = Profile.find(params[:parent_id]).user.email if params[:parent_id]
            @current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
            @school = @current_user.school
            if params[:message_type] && !params[:message_type].nil?
              message = (params[:message_type]=="Friend") ? "Friend request sent" : "Message sent"
              UserMailer.private_message(email,@current_user,@school,@message.content).deliver if message == "Message sent"
              render :text => {"status"=>"save", "message"=>message}.to_json
            else
            UserMailer.private_message(email,@current_user,@school,@message.content).deliver
            @feed = Feed.find(:first,:conditions=>["profile_id = ? and wall_id = ?",user_session[:profile_id],wall_id])
              if @feed.nil?
                Feed.create(:profile_id => user_session[:profile_id],:wall_id =>wall_id)
              end
              render :partial => "messages", :locals => {:message => @message}
            end
          else
           @feed = Feed.find(:first,:conditions=>["profile_id = ? and wall_id = ?",user_session[:profile_id],wall_id])
            if @feed.nil?
              Feed.create(:profile_id => user_session[:profile_id],:wall_id =>wall_id)
            end
            render :partial => "messages", :locals => {:message => @message}
        end
      end
    end
  end 
  
  def like
    if params[:message_id] && !params[:message_id].nil?
      @message = Like.add(params[:message_id], user_session[:profile_id],params[:course_id])
      if @message
        render :text => {"action"=>"unlike", "count"=>@message.like}.to_json
      end
    end
  end
  
  def unlike
    if params[:message_id] && !params[:message_id].nil?
      @message = Like.remove(params[:message_id], user_session[:profile_id], params[:course_id])
      if @message
        render :text => {"action"=>"like", "count"=>@message.like}.to_json
      end
    end
  end
  
  def add_friend_card
    if params[:profile_id] && !params[:profile_id].nil?
      @profile = Profile.find(params[:profile_id])
      course_id = nil
        @current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
        #@owner = Participant.find(:first,:conditions=>["object_id = ? and profile_id = ? and profile_type= 'M' and object_type = 'Course'",params[:course_id],@current_user.id])
        course_ids = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.profile_type = 'M' and participants.object_type = 'Course' and parent_type = 'C' and removed = ?", user_session[:profile_id],false])
        @courses = Course.find(:all, :include => [:participants], :conditions=>["participants.profile_id = ? and participants.object_id in(?) and participants.profile_type = 'S' and participants.object_type = 'Course' and parent_type = 'C'", params[:profile_id], course_ids],:order=>"courses.id")
        if @courses && !@courses.empty?
          if params[:course_id] && !params[:course_id].nil?
            course_id = params[:course_id]
          else
            course_id = @courses.first.id
          end
          @participant = Participant.find(:first, :conditions =>["object_id = ? and profile_id = ? and object_type = 'Course' and profile_type='S'",course_id,@profile.id])
        end  
      render :partial => "add_friend_card", :locals => {:profile => @profile}
    end
  end
  
  def respond_to_course_request
     if params[:message_id] && !params[:message_id].nil?
      @message = Message.find(params[:message_id])
      p_id = Profile.find(user_session[:profile_id])
      if @message
        group_request = false
        action = nil
        content = nil
        if params[:activity] && !params[:activity].nil?
          if params[:activity] == "add"
            action = "accepted"
          else
            action = "rejected"
          end
          course = Course.find(@message.target_id)
          if params[:message_type] == "course_invite"
            content = "#{p_id.full_name} has #{action} your invitation to #{course.name}."
          elsif params[:message_type] == "Friend"
            content = "#{p_id.full_name} has #{action} your friend request."
          elsif params[:message_type] == "group_request"
            content = "#{p_id.full_name} has #{action} your request to join #{course.name}."
          elsif params[:message_type] == "group_invite"
            content = "#{p_id.full_name} has #{action} your invitation to #{course.name}."
          end
          if params[:message_type] == "group_request"
            group_request = true
            profile_id = @message.profile_id
          else
            profile_id = @message.parent_id
          end
					
          @course_participant = Participant.where("object_type = ? AND object_id = ? AND profile_id = ? AND profile_type='P'",params[:section_type],@message.target_id,profile_id).first
          tasks = Task.find(:all, :conditions => ["course_id = ? and archived = ? and all_members = ?", @message.target_id, false, true])
          if tasks and !tasks.blank?
						if params[:activity] == "add"
							tasks.each do |t|
								wall_id = Wall.get_wall_id(t.id,"Task")
								task_owner = TaskParticipant.find(:first, :conditions => ["task_id = ? AND profile_type='O'", t.id])
								task_member = TaskParticipant.where("task_id = ? AND profile_id = ?", t.id,p_id.id).count
								if task_owner && task_member == 0
									@profile = Profile.find(task_owner.profile_id)
									@task_participant = TaskParticipant.new
									@task_participant.profile_id = user_session[:profile_id]
									@task_participant.profile_type = "M"
									@task_participant.status = "A"
									@task_participant.priority = "L"
									@task_participant.task_id = t.id
									if @task_participant.save
										Feed.create(
											:profile_id => user_session[:profile_id],
											:wall_id => wall_id
										)
									participant_content = "#{@profile.full_name} assigned you a new task: #{t.name}"   
									Message.send_notification(@profile.id,participant_content,user_session[:profile_id])    
									end
								end
							end
						end
          end
          forums = Course.find(:all, :conditions => ["course_id = ? and archived = ? and all_members = ?", @message.target_id, false, true])
          if forums and !forums.blank?
						if params[:activity] == "add"
							forums.each do |forum|
								wall_id = Wall.get_wall_id(forum.id,"Course")
								@forum_participant = Participant.new
								@forum_participant.object_id = forum.id
								@forum_participant.object_type = "Course"
								@forum_participant.profile_id = user_session[:profile_id]
								@forum_participant.profile_type = "S"
								if @forum_participant.save
									Feed.create(
										:profile_id => user_session[:profile_id],
										:wall_id => wall_id
									)
								end
							end
						end
          end
					
          if params[:activity] == "add"
            if @course_participant
              @course_participant.profile_type = 'S'
              @course_participant.save
            end
             # Notification according to message type
            @respont_to_course = Message.respond_to_course_invitation(@message.parent_id,@message.profile_id,@message.target_id,content,params[:section_type])
            render :text=> "Added to #{course.name} (#{course.code_section})"
         else
            if @course_participant
             @course_participant.delete
            end
            @respont_to_course = Message.respond_to_course_invitation(@message.parent_id,@message.profile_id,@message.target_id,content,params[:section_type])
            render :text => "friend_list"
         end
         @message.archived = true
         @message.save
          wall_id = Wall.get_wall_id(@message.target_id, "C")
              Feed.create(
                :profile_id => @message.parent_id,
                :wall_id =>wall_id
              )
        end
      end
    end      
  end
  
  def respond_to_friend_request
    if params[:message_id] && !params[:message_id].nil?
      @message = Message.find(params[:message_id])
      profile = Profile.find(user_session[:profile_id])
      if @message 
      already_friend = Participant.find(:first, :conditions =>["object_id = ? AND profile_id = ? AND object_type = 'User' AND profile_type = 'F'", @message.parent_id, @message.profile_id])
        if params[:activity] && !params[:activity].nil?
          if params[:activity] == "add" and not already_friend
            content = "#{profile.full_name} has accepted your friend request."
            @friend_participant = Participant.new
            @friend_participant.object_id = @message.parent_id
            @friend_participant.object_type = "User"
            @friend_participant.profile_id = @message.profile_id
            @friend_participant.profile_type = "F"
            if @friend_participant.save
              Feed.create(
                :wall_id => @message.wall_id,
                :profile_id => @friend_participant.profile_id
              )
              #Participant record for friend
              @participant = Participant.new
              @participant.object_id = @message.profile_id
              @participant.object_type = "User"
              @participant.profile_id = @message.parent_id
              @participant.profile_type = "F"
              if @participant.save
                #Feed for friend participant
                Feed.create(
                  :wall_id => @message.wall_id,
                  :profile_id => @participant.profile_id
                )
              end
              @message.archived = true
              @message.save
              Message.send_notification(profile.id,content,@message.profile_id)
              @friend_profile = Profile.find(@message.parent_id)
              render :partial => "friend_list", :locals=>{:friend=>@friend_profile}
            end
          elsif params[:activity] == "dntadd"
            content = "#{profile.full_name} has rejected your friend request."
            Message.send_notification(profile.id,content,@message.profile_id)
            @message.archived = true
            @message.save
            render :nothing=>true
          end
        end
      end
    end
  end
  
  def unfriend
    status = false
    if params[:profile_id] && ![:profile_id].nil?
      @friend_participant = Participant.find(
        :first, 
        :conditions=>["object_id = ? AND profile_id = ? AND profile_type = 'F'", user_session[:profile_id], params[:profile_id]]
      )
      if @friend_participant
        @friend_participant.delete
        @participant = Participant.find(
          :first, 
          :conditions=>["object_id = ? AND profile_id = ? AND profile_type = 'F'",params[:profile_id] , user_session[:profile_id]]
        )
        if @participant
          @participant.delete
        end
        status = true
      end
    end
    render :text => {"status"=>status}.to_json
  end
  
  def add_note
    if params[:parent_id] && !params[:parent_id].nil?
      @note = Note.new
      @note.profile_id = user_session[:profile_id]
      @note.about_object_id = params[:parent_id]
      @note.about_object_type = "Note"
      @note.content = params[:content]
      if @note.save
        render :text => {"status"=>"save"}.to_json
      end
    end
  end
  
  def friend_messages
    if params[:profile_id]
      #@messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend'", wall_ids, false])
    end
  end
  
 

  def show_all
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?",user_session[:profile_id]]).collect(&:wall_id)
    @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend'", wall_ids, false])
    @friend_requests = Message.find(:all, :conditions=>["message_type ='Friend' AND parent_id = ? AND (archived is NULL or archived = ?)", user_session[:profile_id], false])
    @friend = Participant.find(:all, :conditions=>["object_id = ? AND object_type = 'User' AND profile_type = 'F'", user_session[:profile_id]])
    render :partial => "list",:locals => {:limit => @limitAttr}
  end
  
  
   def friends_only
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?",user_session[:profile_id]]).collect(&:wall_id)
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", user_session[:profile_id]]).collect(&:message_id)
    profile = Profile.find(user_session[:profile_id])
    @friend = Profile.find(params[:friend_id]) 
    @messages = Message.find(:all, :conditions => ["(archived is NULL or archived = ?) AND ((profile_id= ? and  parent_id = ?) or (profile_id = ? and parent_id = ?)) AND message_type ='Message' AND parent_type!='Message' and target_type not in('Notification','Course','Group') and id in(?)",false,params[:friend_id],user_session[:profile_id],user_session[:profile_id],params[:friend_id],message_ids], :order => 'created_at DESC')
    profile.record_action('message', @friend.id)
    profile.record_action('last', 'message')
    if @messages and !@messages.blank?
      @messages.each do |message|
        message_viewer =MessageViewer.find(:first, :conditions => ["(archived is NULL or archived = ?) AND message_id = ? AND poster_profile_id = ? AND viewer_profile_id = ?",false,message.id,params[:friend_id],user_session[:profile_id]], :order => "created_at DESC")
        message_viewer.update_attribute("viewed",true) if message_viewer
        comments = comment_list(message.id).collect(&:id)
        if comments
          comments.each do |comment_id|
            comment_message_viewer = MessageViewer.find(:first, :conditions => ["(archived is NULL or archived = ?) AND message_id = ? AND poster_profile_id = ? AND viewer_profile_id = ?",false,comment_id,params[:friend_id],user_session[:profile_id]], :order => "created_at DESC")
            comment_message_viewer.update_attribute("viewed",true) if comment_message_viewer
          end
        end
      end
    end
    render :partial => "list",:locals => {:friend_id =>params[:friend_id]}
  end 
  
  
  def notes
    if params[:friend_id] && !params[:friend_id].nil?
      @notes = Note.find(:all, :conditions => ["profile_id = ? AND about_object_id = ? AND about_object_type = 'Note' ",user_session[:profile_id],params[:friend_id]])
      render :partial => "list",:locals => {:friend_id =>params[:friend_id]}
    end
  end
  
  def friends_only_all
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?",user_session[:profile_id]]).collect(&:wall_id)
    @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND profile_id=? AND message_type ='Message' AND parent_type='Profile'", wall_ids, false,params[:friend_id]])  
    render :partial => "list",:locals => {:limit => @limitAttr}
  end
  
  def remove_request_message
    if params[:id] && !params[:id].nil?
      delete_notification(params[:id]) unless eval(params[:id]).kind_of?(Array)
      eval(params[:id]).each {|id| delete_notification(id)} if eval(params[:id]).kind_of?(Array)
      render :json => {:status => true}
    end
  end
  
    
  def confirm
    if params[:id] && !params[:id].nil?
      course_master = params[:course_master_id] if params[:course_master_id]
      @del = false
      @message = Message.find(params[:id])
      if course_master and !course_master.nil?
        if course_master.to_i != user_session[:profile_id]
          comments_ids = Message.find(:all, :select => "distinct profile_id", :conditions=>["parent_id = ?",params[:id]]).collect(&:profile_id)
          comments_ids.each do |c|
            if c != user_session[:profile_id]
              @del = true
              break
            end
          end
      
        end 
      end        
      render :partial => "message/warning_box",:locals =>{:@message_id =>@message.id, :@type=>params[:message_type], :@delete_all=>params[:delete_all],:@del=>@del}
    end
  end  
  
  def delete_message
    if params[:id] && !params[:id].nil?
      comments_ids = Message.find(:all, :select => "id", :conditions=>["parent_id = ?",params[:id]]).collect(&:id)
      Message.update_all({:archived => true},["id = ?",params[:id]])
      Message.update_all({:archived => true},["id in (?)",comments_ids])
      if params[:delete_all] and params[:delete_all]=="delete_all"
        MessageViewer.delete_all(["message_id = ?", params[:id]])
        MessageViewer.delete_all(["message_id in(?)",comments_ids])
      else
        @message_viewer = MessageViewer.find(:first, :conditions=>["viewer_profile_id = ? and message_id = ?", user_session[:profile_id], params[:id]])
        if @message_viewer
          MessageViewer.delete_all(["message_id in(?) and viewer_profile_id = ?",comments_ids, user_session[:profile_id]])
          @message_viewer.delete    
        end
      end
      render :json => {:status => true}
    end  
  end
  
  def save_topic
    if params[:id] and !params[:id].nil?
      @message = Message.find(params[:id])
      if @message
        @message.topic = params[:content]
        @message.save
        render :json => {:status => true}
      end
    end
  end
  
  private
  
  def delete_notification(message_id)
    @message = MessageViewer.find(:first, :conditions=>["viewer_profile_id = ? and message_id = ?", user_session[:profile_id], message_id])
    @message.delete if @message
  end
  
end