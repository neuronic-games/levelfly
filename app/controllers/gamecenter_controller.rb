class GamecenterController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!, :except => [:status]

  def status
    message = "All ok"
    status = Gamecenter::SUCCESS
    
    render :text => { 'status' => status, 'message' => message }.to_json
  end

  # Login the player to GameCenter
  def authenticate
    message = ""
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
    conditions = ["apps.school_id = ?", school_id]

    if filter == "active"
      conditions[0] += " and apps.archived = ?"
      conditions << false
    elsif filter == "archived"
      conditions[0] += " and apps.archived = ?"
      conditions << true
    end
        
    @apps = App.find(:all, :conditions => conditions,
      :order => "name")
    
    render :partial => "/gamecenter/rows"
  end
  
  def add_game
    @app = App.new
    
    @app.name = "Application Name"
    @app.descr = "Description"
    @app.last_rev = "v 1.0"
    
    render :partial => "/gamecenter/form"
  end
  
  def save_game
  end
  
end
