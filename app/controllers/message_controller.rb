class MessageController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @messages = Message.find(:all, :conditions=>["profile_id = ? AND parent_type !='Message'", user_session[:profile_id]])
    render :partial => "list"
  end
  
  def save
    if params[:parent_id] && !params[:parent_id].nil?
      @message = Message.create(
        :profile_id=>user_session[:profile_id], 
        :parent_id=>params[:parent_id], 
        :parent_type=>params[:parent_type], 
        :content=>params[:content],
        :post_date=>DateTime.now
      )
      if @message.save
        if params[:parent_type] == "Message"
          render :partial => "comments", :locals => {:comment => @message}
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
end
