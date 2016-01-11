class GamecenterController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!

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

    # filter is "school", "course" or "friend"
    filter = params[:filter]
    
    school_id = @profile.school_id
    conditions = ["profiles.archived = ? and profiles.school_id = ? and user_id is not null", false, school_id]

    if filter == "course"
      course_ids = Participant.find(:all, 
        :conditions => ["target_type = 'Course' and profile_id = ? and profile_type in ('M', 'S')", @profile.id], 
        :select => "distinct target_id as course_id").map(&:course_id)
      conditions[0] += " and participants.target_type = 'Course' and participants.profile_type in ('M', 'S') and participants.target_id in (?)"
      conditions << course_ids
    elsif filter == "friend"
      conditions[0] += " and participants.target_type = 'User' and participants.profile_type = 'F' and participants.target_id = ?"
      conditions << @profile.id
    end
    if params[:show] and !params[:show]
      profiles_temp = Profile.find(:all, :conditions => conditions,
      :include => [:participants],
      :order => "xp desc")
    else
      profiles_temp = Profile.find(:all, :limit => 50,
      :conditions => conditions,
      :include => [:participants],
      :order => "xp desc")
    end
    
        
    if filter == "friend"
      profiles_temp << @profile
      profiles_temp = profiles_temp.sort_by{|a| a.xp}.reverse
    end
    #provide rank to each user
    profiles_temp.each_with_index do |p,i|
      p[:rank] = i + 1
    end
    # for show me, will send a list with current user on third position.
    index = profiles_temp.index(@profile)
    if params[:show] and !params[:show].nil? and !index.nil? and index > 2
        start = index - 2
        end_point = 46
        @profiles = profiles_temp[start..index] + profiles_temp[index+1..end_point]
    else
      @profiles = profiles_temp
    end

    render :partial => "/gamecenter/rows"
  end

end
