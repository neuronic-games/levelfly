class LeaderBoardController < ApplicationController

  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
      if @profile
        @courses = Course.find(:all)
        @courses_list = Course.joins(:participants => [{:profile => :avatar}]).where(" participants.object_type = 'Course'").select("profiles.full_name,avatars.level,avatars.points,courses.name,profiles.image_file_name")
      end  
      respond_to do |wants|  
        wants.html do
          if request.xhr?
            render :partial => "/leader_board/list"
          else
            render
          end
        end
      end
  end
  
  def show_user_profile
    if params[:course_id] && !params[:course_id].nil?
       @courses_list = Course.joins(:participants => [{:profile => :avatar}]).where(" participants.object_type = 'Course' AND courses.id = ?",params[:course_id]).select("profiles.full_name,avatars.level,avatars.points,courses.name,profiles.image_file_name")
    end
    render :partial => "/leader_board/courses_list"
  end
  
end
