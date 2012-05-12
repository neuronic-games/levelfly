class FriendController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
  
    if params[:search_text]
      search_text =  "#{params[:search_text]}"
      @friend = Profile.joins(:participants).where("object_id = ? AND object_type = 'User' AND profile_type = 'F' AND profiles.full_name LIKE '#{params[:search_text]}%'",user_session[:profile_id])
     end  
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/friend/list"
        else
          render
        end
      end
    end
  end

end
