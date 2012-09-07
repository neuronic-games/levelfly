class RewardController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @profile = Profile.find(user_session[:profile_id])
    render :partial => "/reward/list"
    #@profile.record_action('last', 'leader_board')
  end

end
