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
        :conditions => ["object_type = 'Course' and profile_id = ? and profile_type in ('M', 'S')", @profile.id], 
        :select => "distinct object_id as course_id").map(&:course_id)
      conditions[0] += " and participants.object_type = 'Course' and participants.profile_type in ('M', 'S') and participants.object_id in (?)"
      conditions << course_ids
    elsif filter == "friend"
      conditions[0] += " and participants.object_type = 'User' and participants.profile_type = 'F' and participants.object_id = ?"
      conditions << @profile.id
    end
    
    @profiles = Profile.find(:all, :limit => 50,
      :conditions => conditions,
      :include => [:participants],
      :order => "xp desc")
      
    if filter == "friend"
      @profiles << @profile
      @profiles = @profiles.sort_by{|a| a.xp}.reverse
    end

    render :partial => "/leader_board/rows"
  end
  
  def show_user_profile
    if params[:course_id] && !params[:course_id].nil?
       @courses_list = Course.joins(:participants => [{:profile => :avatar}]).where("participants.object_type = 'Course' AND courses.id = ?",params[:course_id]).select("profiles.full_name,avatars.level,avatars.points,courses.name,profiles.image_file_name")
    end
    render :partial => "/leader_board/courses_list"
  end
  
end
