class CourseController < ApplicationController
  layout 'teacher'
  before_filter :authenticate_user!
  
  def index
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if @profile
      user_session[:profile_id] = @profile.id
    end
    @people = Profile.find(:all, :conditions => ["user_id != ? AND school_id = ?", current_user.id, @profile.school_id ])
  end
  
  def save
    if params[:id] && !params[:id].empty?
      @course = Course.find(params[:id])
    else
      # Save a new course
      @course = Course.new
    end
    
    @course.name = params[:course]
    @course.descr = params[:descr]
    @course.code = params[:code]
    @course.campus_id = params[:campus_id]
    
    if @course.save
      # Participant record
      participant = Participant.find(:first, :conditions => ["object_id = ? AND profile_id = ?", @course.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.object_id = @course.id
        @participant.object_type = "Course"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        @participant.save
      end
    end
    
    render :text => {"course"=>@course}.to_json
  end
  
end
