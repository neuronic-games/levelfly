class RewardController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  before_filter :check_role
  def index
    @profile = Profile.find(user_session[:profile_id])
    @rewards = Reward.all(:order=>"xp asc")
    render :partial => "/reward/list"
    #@profile.record_action('last', 'leader_board')
  end
  
  def new 
   render :partial => "/reward/form"
  end
  
  def show
    if params[:id] and !params[:id].nil?
      @reward = Reward.find(params[:id])
      if @reward
        render :partial => "/reward/form"
      end
    end
  end
 
  def save
    if params[:id] and !params[:id].blank?
      @reward = Reward.find(params[:id])
    else
      @reward = Reward.new
    end
    @reward.xp = params[:xp] if params[:xp]
    @reward.object_type = params[:object_type] if params[:object_type]
    @reward.object_id = params[:object_id] if params[:object_id]
    if @reward.save
      render :text => {:status=>true}.to_json 
    end
  end
  
  def delete
    if params[:id] and !params[:id].blank?
      reward = Reward.find(params[:id])
      if reward
        reward.delete
        render :text =>{:status=>true}.to_json
      end
    end
  end
  
  def check_role
    if Role.check_permission(user_session[:profile_id],Role.modify_rewards)==false
      render :text=>""
    end
  end

end
