class MessageController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
 def index
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?",user_session[:profile_id]]).collect(&:wall_id)

    if params[:search_text]
      search_text =  "%#{params[:search_text]}%"
      @comment_ids = Message.limit(2).find(:all,
        :select => "parent_id", 
        :conditions => ["(archived is NULL or archived = ?) AND parent_type = 'Message' AND content LIKE ? ", false, search_text]).collect(&:parent_id)
      @messages = Message.limit(2).find(:all, 
        :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend' AND (content LIKE ? OR id in (?) )", wall_ids, false, search_text, @comment_ids])
      @messagesAll = Message.count(:all, 
        :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend' AND (content LIKE ? OR id in (?) )", wall_ids, false, search_text, @comment_ids])
    elsif params[:friend_id]
      @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND profile_id=? AND message_type ='Message' AND parent_type='Profile'", wall_ids, false,params[:friend_id]])  
      @messagesAll = Message.count(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend'", wall_ids, false]) 
    else
      @messages = Message.limit(2).find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend'", wall_ids, false])
      @messagesAll = Message.count(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND message_type !='Friend'", wall_ids, false]) 
      @friend_requests = Message.limit(2).find(:all, :conditions=>["message_type ='Friend' AND parent_id = ? AND (archived is NULL or archived = ?)", user_session[:profile_id], false])
    end
    @friend = Participant.find(:all, :conditions=>["object_id = ? AND object_type = 'User' AND profile_type = 'F'", user_session[:profile_id]])
    
    if @messagesAll > 2
       @limitAttr = 2
    end
    render :partial => "list",:locals => {:limit => @limitAttr,:friend_id => @friend_id}
  end
  
  
  def save
    if params[:parent_id] && !params[:parent_id].nil?
      @message = Message.new
      @message.profile_id = user_session[:profile_id]
      @message.parent_id = params[:parent_id]
      @message.parent_type = params[:parent_type]
      @message.content = params[:content]
      @message.message_type = params[:message_type] if params[:message_type]
      @message.wall_id = Wall.get_wall_id(params[:parent_id], params[:parent_type]) #params[:wall_id]
      @message.post_date = DateTime.now
      
      if @message.save
        case params[:parent_type]
          when "Message"
            render :partial => "comments", :locals => {:comment => @message}
          when "Profile"
            message = (params[:message_type]=="Friend") ? "Friend request has been sent!!" : "Message has been sent!!"
            render :text => {"status"=>"save", "message"=>message}.to_json
          else
            render :partial => "messages", :locals => {:message => @message}
        end
      end
    end
  end
  
  def like
    if params[:message_id] && !params[:message_id].nil?
      @message = Message.find(params[:message_id])
      if(@message)
        @message.like = @message.like + 1
        @message.save
        @like = Like.create(:message_id=>@message.id, :profile_id=>user_session[:profile_id])
        render :text => {"action"=>"unlike", "count"=>@message.like}.to_json
      end
    end
  end
  
  def unlike
    if params[:message_id] && !params[:message_id].nil?
      @message = Message.find(params[:message_id])
      if(@message)
        @message.like = @message.like - 1
        @message.save
        @like = Like.find(:first, :conditions=>["message_id = ? AND profile_id = ?", @message.id,user_session[:profile_id]])
        @like.destroy if @like
        render :text => {"action"=>"like", "count"=>@message.like}.to_json
      end
    end
  end
  
  def add_friend_card
    if params[:profile_id] && !params[:profile_id].nil?
      @profile = Profile.find(params[:profile_id])
      render :partial => "add_friend_card", :locals => {:profile => @profile}
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
    @messages = Message.limit(2).find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND profile_id=? AND message_type ='Message' AND parent_type='Profile'", wall_ids, false,params[:friend_id]])  
    @messagesAll = Message.count(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND profile_id=? AND message_type ='Message' AND parent_type='Profile'", wall_ids, false,params[:friend_id]])  
    if @messagesAll > 2
       @limitAttr = 2	
    end
    render :partial => "list",:locals => {:limit => @limitAttr,:friend_id =>params[:friend_id]}
  end
  
  def friends_only_all
    wall_ids = Feed.find(:all, :select => "wall_id", :conditions =>["profile_id = ?",user_session[:profile_id]]).collect(&:wall_id)
    @messages = Message.find(:all, :conditions => ["wall_id in (?) AND (archived is NULL or archived = ?) AND profile_id=? AND message_type ='Message' AND parent_type='Profile'", wall_ids, false,params[:friend_id]])  
    render :partial => "list",:locals => {:limit => @limitAttr}
  end
end