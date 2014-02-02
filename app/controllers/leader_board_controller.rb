class LeaderBoardController < ApplicationController

  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @profile = Profile.find(user_session[:profile_id])
    render :partial => "/leader_board/list"
    @profile.record_action('last', 'leader_board')
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

    render :partial => "/leader_board/rows"
  end
  
  def show_user_profile
    if params[:course_id] && !params[:course_id].nil?
       @courses_list = Course.joins(:participants => [{:profile => :avatar}]).where("participants.target_type = 'Course' AND courses.id = ?",params[:course_id]).select("profiles.full_name,avatars.level,avatars.points,courses.name,profiles.image_file_name")
    end
    render :partial => "/leader_board/courses_list"
  end
  
end
