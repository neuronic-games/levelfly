class MessageController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @messages = Message.find(:all, :conditions=>["parent_type !='Message' AND message_type !='Friend'"])
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
end
