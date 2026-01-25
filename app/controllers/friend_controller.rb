class FriendController < ApplicationController
  layout 'main'
  before_action :authenticate_user!

  def index
    if params[:search_text]
      params[:search_text].to_s
      @friend = Profile.where("upper(profiles.full_name) LIKE '#{params[:search_text].upcase}%'")
    end
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render partial: '/friend/list'
        else
          render
        end
      end
    end
  end
end
