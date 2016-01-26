class GamecenterController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!, :except => [:status, :connect, :authenticate, :get_current_user, :add_progress]

  def status
    message = "All OK"
    status = Gamecenter::SUCCESS
    
    render :text => { 'status' => status, 'message' => message }.to_json
  end

  # Login the player to GameCenter
  def authenticate
    message = ""
    status = Gamecenter::FAILURE
    data = {}
    
    user = User.find_by_email(params[:username])
    if user && user.valid_password?(params[:password])
      sign_out current_user
      sign_in user
      status = Gamecenter::SUCCESS
      profile = user.default_profile
      message = "#{profile.full_name} signed in"
      data = { 'alias' => profile.full_name, 'level' => profile.level, 'image' => profile.image_file_name, 'last_sign_in_at' => user.last_sign_in_at }
    end

    render :text => { 'status' => status, 'message' => message, 'user' => data }.to_json
  end
  
  def connect
    message = "Unknown error"
    status = Gamecenter::FAILURE
    data = {}
    
    handle = params[:handle]
    game = Game.find_by_handle(handle)
    if game
      message = "Connected to #{game.name}"
      status = Gamecenter::SUCCESS
      data = { 'name' => game.name, 'id' => game.id, 'player_count' => game.player_count }
    else
      message = "Game with handle #{handle} does not exist"
    end
    
    render :text => { 'status' => status, 'message' => message, 'game' => data }.to_json
  end
  
  # Returns the current user that was authenticated
  def get_current_user
    message = ""
    status = Gamecenter::FAILURE
    data = {}
    
    if current_user
      status = Gamecenter::SUCCESS
      profile = current_user.default_profile
      message = "#{profile.full_name} signed in"
      data = { 'alias' => profile.full_name, 'level' => profile.level, 'image' => profile.image_file_name, 'last_sign_in_at' => current_user.last_sign_in_at }
    end

    render :text => { 'status' => status, 'message' => message, 'user' => data }.to_json
  end

  # Adds a player's progress to a game by creating a Feat record
  def add_progress
    game_id = params[:game_id]
    progress = params[:progress]
    progress_type = params[:progress_type]    
    level = params[:level]    
    
    feat = Feat.new(:game_id => game_id, :profile_id => current_user.default_profile.id)
    feat.progress = progress
    feat.progress_type = progress_type
    feat.level = level
    feat.save

    message = "Progress recorded for game #{game_id} for user profile #{current_user.default_profile.id}"
    status = Gamecenter::SUCCESS

    render :text => { 'status' => status, 'message' => message }.to_json

  end
  
  # Returns 50 top scores for your game
  def list
    message = ""
    status = Gamecenter::SUCCESS
    
    render :text => { 'status' => status, 'message' => message }.to_json
  end

  # Update the player's progress in the game
  def update
    message = ""
    status = Gamecenter::SUCCESS
    
    render :text => { 'status' => status, 'message' => message }.to_json
  end

  # Returns the player's progress in the game
  def view
    message = ""
    status = Gamecenter::SUCCESS
    
    gc = Gamecenter.new
    
    render :text => { 'status' => status, 'message' => message, 'progress' => gc }.to_json
  end

  # web UI
  
  def index
    @profile = Profile.find(user_session[:profile_id])
    render :partial => "/gamecenter/list"
    @profile.record_action('last', 'gamecenter')
  end
  
  def get_rows
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])

    # filter is "active", "archived"
    filter = params[:filter]
    
    school_id = @profile.school_id
    conditions = ["apps.handle is not null"]

    if filter == "active"
      conditions[0] += " and apps.archived = ?"
      conditions << false
    elsif filter == "archived"
      conditions[0] += " and apps.archived = ?"
      conditions << true
    end
        
    @apps = Game.find(:all, :conditions => conditions,
      :order => "name")
    
    render :partial => "/gamecenter/rows"
  end
  
  def add_game
    @app = Game.new
    
    @app.name = "Application Name"
    @app.descr = "Description"
    @app.last_rev = "v 1.0"
    
    render :partial => "/gamecenter/form"
  end
  
  def save_game
  end
  
end
