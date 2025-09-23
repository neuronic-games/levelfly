class SettingController < ApplicationController
  layout 'main'
  before_action :authenticate_user!
  before_action :check_role

  def index
    @profile = Profile.find(user_session[:profile_id])
    @settings = Setting.where(['target_id = ?', @profile.school_id])
    render partial: '/setting/list'
  end

  def new
    @profile = Profile.find(user_session[:profile_id])
    render partial: '/setting/form'
  end

  def show
    if params[:id] and !params[:id].blank?
      @profile = Profile.find(user_session[:profile_id])
      @setting = Setting.find(params[:id])
      render partial: '/setting/form' if @setting
    end
  end

  def save
    profile = Profile.find(user_session[:profile_id])
    @setting = if params[:id] and !params[:id].blank?
                 Setting.find(params[:id])
               else
                 Setting.new
               end
    @setting.name = params[:name] if params[:name]
    @setting.target_type = params[:target_type] if params[:target_type]
    @setting.target_id = params[:target_id] if params[:target_id]
    @setting.value = params[:value] if params[:value]
    render text: { status: true }.to_json if @setting.save
  end

  def delete
    if params[:id] and !params[:id].blank?
      setting = Setting.find(params[:id])
      if setting
        setting.delete
        render text: { status: true }.to_json
      end
    end
  end

  def check_role
    render text: '' if Role.check_permission(user_session[:profile_id], Role.modify_settings) == false
  end
end
