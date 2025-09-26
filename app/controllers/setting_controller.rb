class SettingController < ApplicationController
  layout 'main'
  before_action :authenticate_user!
  before_action :check_role

  def index
    @profile = Profile.find(user_session[:profile_id])
    @settings = Setting.where(['target_id = ?', @profile.school_id])
    render partial: '/setting/list'
  end

  def show
    return unless params[:id] and params[:id].present?

    @profile = Profile.find(user_session[:profile_id])
    @setting = Setting.find(params[:id])
    render partial: '/setting/form' if @setting
  end

  def new
    @profile = Profile.find(user_session[:profile_id])
    render partial: '/setting/form'
  end

  def save
    Profile.find(user_session[:profile_id])
    @setting = if params[:id] and params[:id].present?
                 Setting.find(params[:id])
               else
                 Setting.new
               end
    @setting.name = params[:name] if params[:name]
    @setting.target_type = params[:target_type] if params[:target_type]
    @setting.target_id = params[:target_id] if params[:target_id]
    @setting.value = params[:value] if params[:value]
    render body: { status: true }.to_json if @setting.save
  end

  def delete
    return unless params[:id] and params[:id].present?

    setting = Setting.find(params[:id])
    return unless setting

    setting.delete
    render body: { status: true }.to_json
  end

  def check_role
    render body: '' if Role.check_permission(user_session[:profile_id], Role.modify_settings) == false
  end
end
