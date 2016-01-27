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
    game_id = params[:game_id]
    message = ""
    status = Gamecenter::FAILURE
    user = {}
    score = 0
    xp = 0
    
    if current_user
      status = Gamecenter::SUCCESS
      profile = current_user.default_profile
      game = Game.find(game_id)
      score = game.get_score(profile.id)
      xp = game.get_xp(profile.id)
      message = "#{profile.full_name} signed in"
      user = { 'alias' => profile.full_name, 'level' => profile.level, 'image' => profile.image_file_name, 'last_sign_in_at' => current_user.last_sign_in_at }
    end

    render :text => { 'status' => status, 'message' => message, 'user' => user, 'score' => score, 'xp' => xp }.to_json
  end

  # Adds a player's progress to a game by creating a Feat record
  def add_progress
    game_id = params[:game_id]
    progress = params[:progress]
    progress_type = params[:progress_type]
    addition = params[:add] == "true"
    
    level = params[:level]  # May be nil
    profile_id = current_user.default_profile.id
    
    feat = Feat.new(:game_id => game_id, :profile_id => profile_id)
    feat.progress = progress
    feat.progress_type = progress_type
    feat.level = level

    # Check the value based on type
    case feat.progress_type
    when Feat.xp
      # Look up the last XP stored for the game. We will need to update the player's XP
      # with the difference
      game = Game.find(game_id)
      last_xp = game.get_xp(profile_id)
      feat.progress += last_xp if addition
      if feat.progress <= 1000
        delta_xp = feat.progress - last_xp
        Feat.transaction do
          if delta_xp != 0
            profile = Profile.find(profile_id)
            profile.xp += delta_xp
            profile.save
          end
          feat.save
        end
      end
    when Feat.score
      if addition
        game = Game.find(game_id)
        last_score = game.get_score(profile_id)
        feat.progress += last_score
      end
      Feat.transaction do
        feat.save
        Game.add_score_leader(feat)
      end
    when Feat.badge
      badge = Badge.find(feat.progress)
      feat.save if badge
    when Feat.rating
      feat.save if feat.progress.between?(1, 3)
    else
      feat.save
    end
    
    message = "Progress recorded for game #{game_id} for user profile #{current_user.default_profile.id}"
    status = Gamecenter::SUCCESS

    render :text => { 'status' => status, 'message' => message }.to_json
  end
  
  def add_game_badge
    game_id = params[:game_id]
    name = params[:name]
    descr = params[:descr]
    badge_image_id = params[:badge_image_id]

    @game = Game.find(game_id)
    return if @game.nil?

    @badge = Badge.where(name: name, quest_id: game_id).first
    if @badge.nil?    
      @badge = Badge.new
      @badge.name = name
      descr = "New badge for #{@game.name}" if descr.blank?
      @badge.descr = descr
      badge_image_id = 1 if badge_image_id.to_i == 0
      @badge.badge_image_id = badge_image_id
      @badge.quest_id = game_id  # We can use quest_id for storing game_id for now. But if we want to use if for other purposes, we need quest_type
    else
      @badge.descr = descr unless descr.blank?
      @badge.badge_image_id = badge_image_id unless badge_image_id.to_i == 0
    end
    
    @badge.save
  end
  
  def list_leaders
    game_id = params[:game_id]
    if game_id.to_i == 0
      game_id = Game.select(:id).where(handle: game_id)
    end

    @leaders = GameScoreLeader.where(game_id: game_id).order("score desc")
  end
  
  def list_progress
    limit = params[:count]
    limit = 100 if limit.nil?
    game_id = params[:game_id]
    if game_id.to_i == 0
      game_id = Game.select(:id).where(handle: game_id)
    end

    profile_id = current_user.default_profile.id
    
    feat_list = Feat.select("progress_type, progress, level, created_at")
      .where(game_id: game_id, profile_id: profile_id)
      .order("created_at desc")
      .limit(limit)

    @feats = []
    feat_list.each do |feat|
      case feat.progress_type
      when Feat.login
        game = Game.find(game_id)
        @feats << "[#{feat.created_at}] #{current_user.default_profile.full_name} logged into #{game.name}"
      when Feat.xp
        @feats << "[#{feat.created_at}] #{current_user.default_profile.full_name} has a current XP of #{feat.progress}"
      when Feat.score
        @feats << "[#{feat.created_at}] #{current_user.default_profile.full_name} has a current score of #{feat.progress}"
      when Feat.badge
        badge = Badge.find(feat.progress)
        @feats << "[#{feat.created_at}] #{current_user.default_profile.full_name} acquired #{badge ? badge.name : 'unknown'} badge"
      when Feat.rating
        @feats << "[#{feat.created_at}] #{current_user.default_profile.full_name} acquired #{feat.progress} rating"
      when Feat.level
        @feats << "[#{feat.created_at}] #{current_user.default_profile.full_name}"
      else
        @feats << "[#{feat.created_at}] #{current_user.default_profile.full_name} received feat #{feat.progess} in #{feat.progress.type}"
      end
      @feats.last << " on #{feat.level}" if !feat.level.nil?
    end
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
