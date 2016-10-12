class GamecenterController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!, :except => [:status, :show, :connect, :authenticate, :get_current_user, :add_progress]

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
    
    user = User.find_by_like_email(params[:username])
    if user && user.valid_password?(params[:password])
      sign_out current_user
      sign_in user
      status = Gamecenter::SUCCESS
      profile = user.default_profile
      message = "#{profile.full_name} signed in"
      data = { 'alias' => profile.full_name, 'level' => profile.level, 'image' => profile.image_url, 'last_sign_in_at' => user.last_sign_in_at }
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
    handle = params[:handle]
    message = ""
    status = Gamecenter::FAILURE
    user = {}
    score = 0
    xp = 0
    active_dur = 0
    badges = []
    
    if current_user
      status = Gamecenter::SUCCESS
      profile = current_user.default_profile
      game = Game.find_by_handle(handle)
      score = game.get_score(profile.id)
      xp = game.get_xp(profile.id)
      badges = AvatarBadge.find(:all, :include => [:badge], :select => "id, badge_id", :conditions => ["profile_id = ? and badges.quest_id = ?", profile.id, game.id] ).collect { |x| { 'id' => x.badge.id, 'name' => x.badge.name, 'descr' => x.badge.descr, 'image' => x.badge.image_url } } # game specific?
      message = "#{profile.full_name} signed in"
      user = { 'alias' => profile.full_name, 'level' => profile.level, 'image' => profile.image_url, 'last_sign_in_at' => current_user.last_sign_in_at }

      active_dur = Feat.where(game_id: game.id, profile_id: profile.id, progress_type: Feat.duration)
        .sum(:progress)

    end

    render :text => { 'status' => status, 'message' => message, 'user' => user, 'score' => score, 'xp' => xp, 'badges' => badges }.to_json
  end

  # Returns the number of seconds that the user has been active in the game
  def get_active_dur
    handle = params[:handle]
    message = ""
    status = Gamecenter::FAILURE
    active_dur = 0
    
    if current_user
      status = Gamecenter::SUCCESS
      profile = current_user.default_profile
      game = Game.find_by_handle(handle)
      message = "#{profile.full_name} signed in"

      active_dur = Feat.where(game_id: game.id, profile_id: profile.id, progress_type: Feat.duration)
        .sum(:progress)
    end

    render :text => { 'status' => status, 'message' => message, 'active' => active_dur }.to_json
  end

  # Returns the list of top users by score
  def get_top_users
    handle = params[:handle]
    message = ""
    status = Gamecenter::FAILURE
    all_score = []
    
    if current_user
      status = Gamecenter::SUCCESS
      game = Game.find_by_handle(handle)
      all_score = game.get_all_scores_in_order
      message = "#{all_score.count} score records found"
    end

    render :text => { 'status' => status, 'message' => message, 'all_score' => all_score }.to_json
  end

  # Save a player's progress in a game
  def add_checkpoint
    handle = params[:handle]
    message = ""
    status = Gamecenter::FAILURE

    checkpoint = params[:checkpoint]

    if current_user
      status = Gamecenter::SUCCESS
      profile = current_user.default_profile
      game = Game.find_by_handle(handle)
      
      cp = Checkpoint.where(game_id: game.id, profile_id: profile.id).last

      if cp.nil?
        cp = Checkpoint.new
        cp.profile_id = profile.id
        cp.game_id = game.id
      end
      cp.checkpoint = checkpoint
      cp.save
      
      message = "Checkpoint #{cp.id} saved for #{game.name} for #{profile.full_name}"
    end
    
    render :text => { 'status' => status, 'message' => message }.to_json
  end
  
  def get_checkpoint
    handle = params[:handle]
    message = ""
    status = Gamecenter::FAILURE
    checkpoint = ""

    if current_user
      profile = current_user.default_profile
      game = Game.find_by_handle(handle)
      
      cp = Checkpoint.where(game_id: game.id, profile_id: profile.id).last
      
      if cp
        status = Gamecenter::SUCCESS
        message = "Found checkpoint #{cp.id} recorded on #{cp.updated_at}"
        checkpoint = cp.checkpoint
      end
    end
    
    render :text => { 'status' => status, 'message' => message, 'checkpoint' => checkpoint }.to_json
  end
  
  # Adds a player's progress to a game by creating a Feat record
  def add_progress
    handle = params[:handle]
    game = Game.find_by_handle(handle)
    if game.nil?
      message = "Game with handle #{handle} does not exist"
      status = Gamecenter::FAILURE

      render :text => { 'status' => status, 'message' => message }.to_json
      return
    end
    
    progress = params[:progress]
    progress_type = params[:progress_type]
    name = params[:name]  # This is the name of the badge, or outcome, not the name of the game
    addition = params[:add] == "true"
    unique = params[:unique] == "true"  # Unique badge?
    
    level = params[:level]  # May be nil
    profile_id = current_user.default_profile.id
    
    feat = Feat.new(:game_id => game.id, :profile_id => profile_id)
    feat.progress = progress
    feat.progress_type = progress_type
    feat.level = level

    message = "Progress recorded for game #{game.name} for user profile #{current_user.default_profile.id}."
    status = Gamecenter::SUCCESS

    # Check the value based on type
    case feat.progress_type
    when Feat.xp
      # Look up the last XP stored for the game. We will need to update the player's XP
      # with the difference
      last_xp = game.get_xp(profile_id)
      # The last feat record will have the latest XP. You don't need to add up the feat records.

      # When using the additive mode of recording XP, add up the reported XP to what is already recorded for this game
      if addition
        new_xp = feat.progress + last_xp
        if new_xp > 1000
          feat.progress = 1000
        elsif new_xp < 0
          feat.progress = 0
        else
          feat.progress = new_xp
        end
      end
      
      if feat.progress < 0 or feat.progress > 1000
        message = "Progress not recorded for game #{game.name} for user profile #{current_user.default_profile.id}. XP must be between 0 to 1000."
        status = Gamecenter::FAILURE
      else
        # Only save the feat if the new XP is no more than 1000
        delta_xp = feat.progress - last_xp
        Feat.transaction do
          if delta_xp > 0
            profile = Profile.find(profile_id)
            profile.xp += delta_xp
            profile.save
          end
          feat.save
        end
      end
      
    when Feat.score
      if addition
        last_score = game.get_score(profile_id)
        feat.progress += last_score
      end
      # The latest score record is always assumed to be your accumulative score for the game
      Feat.transaction do
        feat.save
        Game.add_score_leader(feat)
      end

    when Feat.final_score
      # There should be only 1 final_score per game session. This will allow you to compare
      # your progress over multiple sessions.
      Feat.transaction do
        feat.save
      end
      
    when Feat.badge
      Feat.transaction do
        if feat.progress.blank?
          name = game.name if name.blank?
          badge = Badge.find_create_game_badge(game.id, name, "New badge for #{game.name}")
          feat.progress = badge.id
        end
        save_feat = true
        if unique  # We only want to record this feat if the user already doesn't have this badge
          last_feat = Feat.where(progress_type: progress_type, progress: badge.id).first
          save_feat = false if last_feat
          message = "Duplicate badge. Progress not recorded for game #{game.name} for user profile #{current_user.default_profile.id}."
        end
        if save_feat
          # It's ok to receive the same badge more than once, unless the 'unique' parameter is used
          feat.save
          AvatarBadge.add_badge(profile_id, feat.progress)
        end
      end
      
    when Feat.rating
      rating = params[:rating]
      outcome = nil
      if feat.progress.to_i > 0
        outcome = Outcome.find(feat.progress)
      else
        outcome = Outcome.where(game_id: game.id, name: name).first
      end
      if outcome
        feat.save
        outcome_feat = OutcomeFeat.new(outcome_id: outcome.id, feat_id: feat.id, profile_id: profile_id, rating: rating)
        outcome_feat.save
        feat.progress = outcome.id
        feat.save
      else
        message = "Progress not recorded for game #{game.name} for user profile #{current_user.default_profile.id}. Outcome '#{name}' does not exist."
        status = Gamecenter::FAILURE
      end
      
    else
      feat.save
    end
    
    render :text => { 'status' => status, 'message' => message }.to_json
  end
  
  def add_game_badge
    handle = params[:handle]
    game = Game.find_by_handle(handle)
    if game.nil?
      message = "Game with handle #{handle} does not exist"
      status = Gamecenter::FAILURE

      render :text => { 'status' => status, 'message' => message }.to_json
      return
    end

    name = params[:name]
    descr = params[:descr]
    descr = "New badge for #{game.name}" if descr.blank?
    badge_image_id = params[:badge_image_id]

    @badge = Badge.find_create_game_badge(game.id, name, descr, badge_image_id)
  end
  
  def list_leaders
    @leaders = []
    
    handle = params[:handle]
    game = Game.find_by_handle(handle)
    return if game.nil?

    @leaders = GameScoreLeader.where(game_id: game.id).order("score desc")
  end
  
  def list_progress
    handle = params[:handle]
    game = Game.find_by_handle(handle)
    return if game.nil?

    limit = params[:count]
    limit = 100 if limit.nil?

    profile_id = current_user.default_profile.id
    @feats = @game.list_feats(cprofile_id, limit)
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

  def show    
    agent_by_request = request.env["HTTP_USER_AGENT"]
    user_agent = UserAgent.parse(agent_by_request)
    platform = user_agent.platform
    conditions = ["profiles.archived = ? and user_id is not null", false]
    @profiles = Profile.find(:all, :limit => 50,
      :conditions => conditions,
      :include => [:participants],
      :order => "xp desc")
    @game = Game.find(params[:id])

    @download_link = ""
    # ['ios', 'android', 'windows', 'mac', 'linux']
    case platform
      when "Windows"
        @download_link = @game.download_links['windows']
      when "X11"
        @download_link = @game.download_links['linux']
      when "Android"
        @download_link = @game.download_links['android']
      when "Macintosh"
        @download_link = @game.download_links['mac']
      when "iPhone"
        @download_link = @game.download_links['ios']
    end
    @outcomes = @game.outcomes.limit(5)
    respond_to do |format|
      format.html {render :layout => 'public'}
    end
  end

  def get_rows
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    # filter is "active", "archived"
    filter = params[:filter]    
    school_id = @profile.school_id
    school = School.find(school_id)
    conditions = ["games.handle is not null and school_id = ?", school_id]

    if filter == "active"
      conditions[0] += " and games.archived = ?"
      conditions << false
      conditions[0] += " and games.profile_id = ?"
      conditions << @profile.id
    elsif filter == "archived"
      conditions[0] += " and games.archived = ?"
      conditions << true
    end    

    if filter == "active"
      user_feats = Feat.where(:profile_id => @profile.id).select("distinct game_id").pluck(:game_id)
      conditions[0] += " or id IN(?)"
      conditions << user_feats    
    end
    @games = Game.find(:all, :conditions => conditions, :order => "name")
    render :partial => "/gamecenter/rows"
  end
  
  def add_game
    @game = Game.new    
    @game.last_rev = "v 1.0"
    @game.archived = false
    @game.published = false
    @game.school_id = current_user.profiles.first.school_id if current_user.profiles.present?
    @game.mail_to = ENV['SUPPORT_EMAIL']
    1.upto(5) {|i| @game.outcomes.build}
    5.times do
      @game.screen_shots.build      
    end
    render :partial => "/gamecenter/form",locals: {url: gamecenter_save_game_path, current_tab: params[:current_tab]}
  end
  
  def save_game
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    @game = Game.new(params[:game])
    @game.profile_id = @profile.id
    @course = create_forum(@game)
    @game.course_id = @course.id
    @game.mail_to = ENV['SUPPORT_EMAIL'] if @game.mail_to.blank?
      
    @game.save
    # Calls save_game.js
  end

  def view_game    
    @game = Game.find(params[:id])
    @game.mail_to = ENV['SUPPORT_EMAIL'] if @game.mail_to.blank?
    five_screens = 5 - @game.screen_shots.count
    five_screens.times do
      @game.screen_shots.build
    end

    render :partial => "/gamecenter/form",locals: {url: gamecenter_update_game_path(:id =>@game.id), current_tab: params[:current_tab], id: @game.id}
  end

  def edit_game    
    @game = Game.find(params[:id])
    @game.mail_to = ENV['SUPPORT_EMAIL'] if @game.mail_to.blank?
    five_screens = 5 - @game.screen_shots.count
    five_screens.times do
      @game.screen_shots.build
    end

    render :partial => "/gamecenter/form",locals: {url: gamecenter_update_game_path(:id =>@game.id), current_tab: params[:current_tab], id: @game.id}
  end

  def update_game
    params[:game].merge!("image" => params["file"]) if params["file"].present?
    @game = Game.find(params[:id])
    @game.update_attributes(params[:game])
    @game.mail_to = ENV['SUPPORT_EMAIL'] if @game.mail_to.blank?
    forum = @game.course    
    forum.update_attribute(:name, "Support for #{@game.name}") unless !forum.present?
    # if params[:download_tab].present? || params[:support_tab].present?
    #   render :json => {status: true}
    # end

    render :json => {id: @game.id}
    # render :partial => "/gamecenter/form",locals: {url: gamecenter_update_game_path(:id =>@game.id), current_tab: params[:current_tab]}
  end

  def game_details
    @game = Game.find(params[:id])    
    render :partial => "/gamecenter/game_details", locals: {current_tab: params[:current_tab]}
  end

  def download
    @game = Game.find(params[:game_id])
    render :partial => "/gamecenter/download", :locals => {:url => gamecenter_update_game_path }
  end

  def view_game_stats
    @game = Game.find(params[:game_id])
    @feats = @game.list_feats(current_profile.id)
    @outcome_list = @game.list_outcome_ratings(current_profile.id)
    
    badge_id_list = Feat.where(game_id: @game.id, profile_id: @profile.id, progress_type: Feat.badge).select("distinct progress").pluck(:progress)
    @badges = Badge.where(id: badge_id_list)
  
    render :partial => "/gamecenter/game_stats", :locals => {:url => gamecenter_update_game_path }
  end

  def support
    @game = Game.find(params[:game_id])
    unless @game.course.present? 
      forum = create_forum(@game)
      @game.course_id = forum.id
      @game.save
    end
    @course = Course.find_by_id(@game.course_id)
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    @wall = Wall.find(:first,:conditions=>["parent_id = ? AND parent_type='Course'", @course.id])
    if !@profile.nil?
      @badges = AvatarBadge.where("profile_id = ? and course_id = ?",@profile.id,@course.id).count
    end
    xp = TaskGrade.select("sum(points) as total").where("school_id = ? and course_id = ? and profile_id = ?",@profile.school_id,@course.id,@profile.id)
    @course_xp = xp.first.total

    section_type = ['Course','Group']
    @member_count = Profile.course_participants(@course.id, section_type).count

    @member = Participant.find( :first, :conditions => ["participants.target_id = ? AND participants.profile_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('M', 'S')", @course.id, @profile.id])
    @pending_count = Profile.count(
      :all,
      :include => [:participants],
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type IN ('P')", @course.id]
    )
    @courseMaster = Profile.find(
      :first,
      :include => [:participants],
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'M'", @course.id]
      )
    @course_owner = Participant.find(:first, :conditions=>["target_id = ? AND profile_type = 'M' AND target_type='Course'",params[:id]])
    #@totaltask = Task.find(:all, :conditions =>["course_id = ?",@course.id])
    @totaltask = @tasks = Task.filter_by(user_session[:profile_id], @course.id, "current")
    @groups = Group.find(:all, :conditions=>["course_id = ?",@course.id])
    message_ids = MessageViewer.find(:all, :select => "message_id", :conditions =>["viewer_profile_id = ?", @profile.id]).collect(&:message_id)
    message_ids = MessageViewer.find(:all, :select => "message_id").collect(&:message_id) if @member.nil?
    @course_messages = Message.find(:all,:conditions=>["parent_id = ? AND parent_type = 'G' AND archived = ? and id in (?)",@course.id, false, message_ids],:order => "starred DESC, post_date DESC" )
    
    @profile.record_action('course', @course.id)
    @profile.record_action('last', 'course')
    #ProfileAction.add_action(@profile.id, "/course/show/#{@course.id}?section_type=#{params[:section_type]}")
    session[:controller]="course"
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/course/form",:locals=>{:course_new =>false,:section_type => "G", privilege: true}
        else

        end
      end
    end
  end

  # Add badges created for a game
  def all_badges
    @game = Game.find(params[:game_id])
    @badges = []
    if gamecenter_write_access(@game.id)
      @badges = Badge.where(:quest_id => @game.id).order(:id)
    end

    render :partial => "/gamecenter/all_badges", locals: { my_game: @game.my_game?(current_profile.id)}
  end
  
  # Badges I have acquired in a game
  def achivements    
    @game = Game.find(params[:game_id])
    @profile = current_profile
    
    @feats = Feat.where(game_id: @game.id, profile_id: @profile.id, progress_type: Feat.badge).select("distinct progress").pluck(:progress)
    @badges = Badge.where(id: @feats)
    
    render :partial => "/gamecenter/achivements", locals: { my_game: @game.my_game?(@profile.id)}
  end 

  def leaderboard
    @game = Game.find(params[:game_id])    
    @profiles_by_feats = Feat.where(game_id: @game.id).pluck(:profile_id).uniq
    profiles_temp = Profile.where(:id => @profiles_by_feats).order("xp desc")
    profiles_temp.each_with_index do |p,i|
      p[:rank] = i + 1
    end    
    @profiles = profiles_temp
    render :partial => "/gamecenter/leader_board"
  end

  def add_badge    
    @game = Game.find(params[:game_id])
    @badge = Badge.new
    @badge_images = BadgeImage.where("image_file_name not in (?)","gold_badge.png").limit(48)
    render :partial =>"/gamecenter/add_game_badge", :locals=>{:profile_id=>current_user.id, :badge => @badge}
  end

  def edit_badge
    @game = Game.find(params[:game_id])    
    @badge = Badge.find(params[:id])
    @badge_images = BadgeImage.where("image_file_name not in (?)","gold_badge.png").limit(48)
    render :partial =>"/gamecenter/add_game_badge", :locals=>{:profile_id=>current_user.id, :badge => @badge}
  end

  def save_badge    
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])    

    if params[:badge_id].present?
      @badge = Badge.find(params[:badge_id])
      @badge.name = params[:name]
      @badge.descr = params[:descr]
      @badge.creator_profile_id = @profile.id
      message = 'Badge Updated'
    else
      @badge = Badge.new
      @badge.name = params[:name]
      @badge.descr = params[:descr]
      @badge.quest_id = params[:game_id]
      @badge.school_id = @profile.school_id
      @badge.creator_profile_id = @profile.id
      @badge.available_badge_image_id = params[:available_badge_image_id]
      message = 'Badge Created'
    end

    # Badge image
    if params[:available_badge_image_id].present?
      # Use stock badge image
      @badge.badge_image_id = nil
      @badge.available_badge_image_id = params[:available_badge_image_id]
    else
      if params[:badge_image].present?
        # Use uploaded badge image
        params[:available_badge_image_id].present?
        badge_image = BadgeImage.new
        badge_image.image = params[:badge_image]
        badge_image.save!
        @badge.badge_image_id = badge_image.id
        @badge.available_badge_image_id = nil
      end
    end
    
    if @badge.save        
      render :json => {:status => true, :message => message}
    else
      render :json => {:status => false, :message => 'Something went wrong'}
    end
  end

  def create_forum(game)
    @course = Course.new
    @course.name = "Support for "+game.name
    @course.parent_type = 'G'
    @course.school_id = game.school_id
    @course.join_type = 'A'    

    if @course.save
      #get wall id
      wall_id = Wall.get_wall_id(@course.id,"Course")
      # Participant record for master
      participant = Participant.find(:first, :conditions => ["target_id = ? AND target_type='Course' AND profile_id = ?", @course.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.target_id = @course.id
        @participant.target_type = "Course"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        if @participant.save
          Feed.create(
            :profile_id => user_session[:profile_id],
            :wall_id =>wall_id
          )
        end
      end
      return @course
    end

  end

  def export_game_csv
    row = []
    return if params[:game_id].blank?
    
    @game = Game.find(params[:game_id])
    @profile = Profile.find(params[:profile_id])
    
    @profiles_by_feats = Feat.where(game_id: @game.id).pluck(:profile_id).uniq
    profiles = Profile.where(:id => @profiles_by_feats).order("full_name")

    @outcome_list = @game.outcomes
    @outcome_list.delete_if { |outcome| outcome.name.blank? }

    user_csv = CSV.generate do |csv|
    
      row << "Player"
      row << "Course"
      row << "Course Number"
      row << "Semester"
      row << "Year"
      row << "Total Time"
      row << "XP"
      # row << "Correct Answer #"
      # row << "Incorrect Answer #"
      row << "Current Level"
      row << "Score"
      row << "Badge #"
      @outcome_list.each do |outcome|
        row << outcome.name
      end
    
      csv << row

      # Student Name
      # Course Name
      # Course Number
      # Semester
      # Year
      # One column for each successful login: Show date stamp, time spent, and highest score per login
      # Time spent overall
      # XP
      # Number of correct and incorrect answers
      # Current Level
      # Highest Score
      # Number of Badges
      # One column for each outcome: Show rating

      profiles.each do | profile |
        row = []

        # What are the courses that you teach, if any?
        @course_id_list = @profile.find_course_id_master_of
        participant = Participant.where(target_type: Participant.member_of_course, target_id: @course_id_list, profile_type: Participant.profile_type_student, profile_id: profile.id).first

        # Is the person in one of those courses?
        @course = participant ? Course.find(participant.target_id) : nil
        
        # Don't show people who are not in courses unless you are the admin
        next if @course.nil? and !@profile.has_role(Role.modify_settings)

        @outcome_ratings = @game.list_outcome_ratings(profile.id)
        @ratings = {}
        @outcome_ratings.each do | outcome, rating |
          @ratings[outcome.id] = rating
        end
        
        row << profile.full_name
        row << (@course ? @course.name : "")
        row << (@course ? @course.code_section : "")
        row << (@course ? @course.semester : "")
        row << (@course ? @course.year : "")
        row << Time.at(@game.get_duration(profile.id)).utc.strftime("%H:%M")
        row << profile.xp_by_game(@game.id)
        # row << "" #"Correct Answer #"
        # row << "" #"Incorrect Answer #"
        row << @game.get_level(profile.id)
        row << @game.get_score(profile.id)
        row << @game.get_badge_count(profile.id)
        @outcome_list.each do |outcome|
          row << @ratings[outcome.id]
        end
        
        csv << row
      end
    
    end
    
    filename = "game-" + @game.handle + "-" + Date.today.strftime("%Y%m%d") + ".csv"
    send_data(user_csv, :type => 'test/csv', :filename => filename)

  end
  
end
