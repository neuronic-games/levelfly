class MessageController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
 def index
    user_session[:last_check_time] = DateTime.now
    @profile = Profile.find(user_session[:profile_id])
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?", @profile.id]).collect(&:wall_id)
    if params[:search_text]
      search_text =  "%#{params[:search_text]}%"
      @comment_ids = Message.find(:all,
        :select => "parent_id", 
        :conditions => ["(archived is NULL or archived = ?) AND parent_type = 'Message' AND content LIKE ? ", false, search_text]).collect(&:parent_id)
      @messages = Message.find(:all, 
        :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend' AND (content LIKE ? OR id in (?) )", wall_ids, false, search_text, @comment_ids])
      
    elsif params[:friend_id]
      @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND profile_id=? AND message_type ='Message' AND parent_type='Profile'", wall_ids, false, params[:friend_id]])  
    else 
      @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type in ('Message')", wall_ids, false], :order => 'created_at DESC')
      
      @friend_requests = Message.find(:all, :conditions=>["message_type in ('Friend', 'course_invite') AND parent_id = ? AND (archived is NULL or archived = ?)", @profile.id, false])
      
      @respont_to_course = Message.find(:all,:conditions=>["target_type = 'Course' AND message_type = 'Message' AND parent_type='Profile' AND parent_id = ? AND archived =?", @profile.id,false], :order => 'created_at DESC')
    end
    @friend = Participant.find(:all, :conditions=>["object_id = ? AND object_type = 'User' AND profile_type = 'F'", @profile.id])

    @profile.record_action('last', 'message')
    session[:controller]="message"
    render :partial => "list",:locals => {:friend_id => @friend_id} 
  end
  
  def check_request
    @friend_requests = Message.find(:all, :conditions=>["message_type in ('Friend', 'course_invite') AND profile_id = ? AND (archived is NULL or archived = ?) AND created_at > ?", user_session[:profile_id], false,user_session[:last_check_time]])
    render:partial=>"message/friend_request_show",:locals=>{:friend_request => @friend_requests}
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
        case params[:parent_type]
          when "Message"
            @msg = Message.find(params[:parent_id])
            render :partial => "comments", :locals => {:comment => @message,:course_id=>@msg.parent_id}
          when "Profile"
            message = (params[:message_type]=="Friend") ? "Friend request sent" : "Message sent"
            render :text => {"status"=>"save", "message"=>message}.to_json
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
      if params[:course_id] && !params[:course_id].nil?
        @current_user = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
        @owner = Participant.find(:first,:conditions=>["object_id = ? and profile_id = ? and profile_type= 'M' and object_type = 'Course'",params[:course_id],@current_user.id])
        if !@owner.nil?
          @participant = Participant.find(:first, :conditions => ["object_id = ? and profile_id = ? and object_type = 'Course' and profile_type='S'",params[:course_id],@profile.id])
        end  
      end
      @badges = AvatarBadge.select("count(*) as total").where("profile_id = ? ",@profile.id)
      render :partial => "add_friend_card", :locals => {:profile => @profile}
    end
  end
  
  
  def respond_to_course_request
     if params[:message_id] && !params[:message_id].nil?
      @message = Message.find(params[:message_id])
      if @message
        if params[:activity] && !params[:activity].nil?
          @course_participant = Participant.where("object_type = ? AND object_id = ? AND profile_id = ? AND profile_type='P'",params[:section_type],@message.target_id,@message.parent_id).first
          if params[:activity] == "add"
            course = Course.find(@message.target_id)
            if @course_participant
              @course_participant.profile_type = 'S'
              @course_participant.save
            end
             # Respond to course messages
            @respont_to_course = Message.respond_to_course_invitation(@message.parent_id,@message.profile_id,@message.target_id,"Accepted",params[:section_type])
            render :text=> "Added to #{course.name} (#{course.code_section})"
         else
            if @course_participant
             @course_participant.delete
            end
            @respont_to_course = Message.respond_to_course_invitation(@message.parent_id,@message.profile_id,@message.target_id,"Rejected",params[:section_type])
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
      if @message
        if params[:activity] && !params[:activity].nil?
          if params[:activity] == "add"
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
              render :partial => "friend_list", :locals=>{:friend=>@friend_participant}
            end
          else
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
    @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND (profile_id=? or profile_id=?) AND message_type ='Message' AND parent_type!='Message'", wall_ids, false,params[:friend_id],user_session[:profile_id]])  
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
end