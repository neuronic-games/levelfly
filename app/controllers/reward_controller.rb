class RewardController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  before_filter :check_role
  def index
    @profile = Profile.find(user_session[:profile_id])
    @rewards = Reward.all.order('xp asc')
    render partial: '/reward/list'
    # @profile.record_action('last', 'leader_board')
  end

  def new
    render partial: '/reward/form'
  end

  def show
    if params[:id] and !params[:id].nil?
      @reward = Reward.find(params[:id])
      render partial: '/reward/form' if @reward
    end
  end

  def save
    @reward = if params[:id] and !params[:id].blank?
                Reward.find(params[:id])
              else
                Reward.new
              end
    @reward.xp = params[:xp] if params[:xp]
    @reward.target_type = params[:target_type] if params[:target_type]
    @reward.target_id = params[:target_id] if params[:target_id]
    render text: { status: true }.to_json if @reward.save
  end

  def delete
    if params[:id] and !params[:id].blank?
      reward = Reward.find(params[:id])
      if reward
        reward.delete
        render text: { status: true }.to_json
      end
    end
  end

  def check_role
    render text: '' if Role.check_permission(user_session[:profile_id], Role.modify_rewards) == false
  end
end
