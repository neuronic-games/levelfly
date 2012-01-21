class MessageController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    wall_ids = Feed.all(:select => "wall_id", :conditions =>["profile_id = ?",user_session[:profile_id]]).collect(&:wall_id)
    @messages = Message.find(:all, :conditions => ["wall_id in (?)", wall_ids])
    @friend_requests = Message.find(:all, :conditions=>["message_type ='Friend' AND parent_id = ?", user_session[:profile_id]])
    @friend = Participant.find(:all, :conditions=>["object_id = ? AND object_type = 'User' And profile_type = 'F'", user_session[:profile_id]])
    render :partial => "list"
  end
  
  def save
    if params[:parent_id] && !params[:parent_id].nil?
      @message = Message.new
      @message.profile_id = user_session[:profile_id]
      @message.parent_id = params[:parent_id]
      @message.parent_type = params[:parent_type]
      @message.content = params[:content]
      @message.message_type = params[:message_type] if params[:message_type]
      @message.wall_id = params[:wall_id]
      @message.post_date = DateTime.now
      
      if @message.save
        if params[:parent_type] == "Message"
          render :partial => "comments", :locals => {:comment => @message}
        elseif params[:parent_type] == "Profile"
          render :text => {"status"=>"sent"}.to_json
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
            @participant = Participant.new
            @participant.object_id = @message.parent_id
            @participant.object_type = "User"
            @participant.profile_id = @message.profile_id
            @participant.profile_type = "F"
            if @participant.save
              Feed.create(
                :object_id => @participant.object_id,
                :object_type => "Profile",
                :profile_id => @participant.profile_id
              )
              @message.destroy
            end
          else
            @message.destroy
          end
        end
      end
    end
    render :text => {"status"=>"done"}.to_json
  end
end
