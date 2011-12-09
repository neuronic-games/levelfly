class CourseController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if @profile
      user_session[:profile_id] = @profile.id
      user_session[:profile_name] = @profile.full_name
      user_session[:profile_major] = @profile.major.name
      user_session[:profile_school] = @profile.school.code
    end
    @courses = Course.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.profile_id = ?", @profile.id]
    )
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/course/list"
        else
          render
        end
      end
    end
  end
  
  def new
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    @people = Profile.find(:all, :conditions => ["user_id != ? AND school_id = ?", current_user.id, @profile.school_id ])
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/course/form"
        else
          render
        end
      end
    end
  end
  
  def show
    @course = Course.find_by_id(params[:id])
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    #@people = Profile.find(:all, :conditions => ["user_id != ? AND school_id = ?", current_user.id, @profile.school_id ])
    @people = Profile.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'S'", @course.id]
    )
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/course/form"
        else
          render
        end
      end
    end
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
    @course.school_id = params[:school_id]
    
    if @course.save
      #Save categories
      categories_array = params[:categories].split(",")
      categories_array.each do |category|
        @category = Category.create(
          :name=> category,
          :course_id=> @course.id,
          :school_id=> @course.school_id
        )
      end
      
      #Save outcomes
      outcomes_array = params[:outcomes].split(",")
      outcomes_array.each do |outcome|
        @outcome = Outcome.create(
          :name=> outcome,
          :descr=> outcome,
          :course_id=> @course.id,
          :school_id=> @course.school_id
        )
      end
      
      # Participant record for master
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Course' AND profile_id = ?", @course.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.object_id = @course.id
        @participant.object_type = "Course"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        @participant.save
      end
      
      peoples_array = params[:people_id].split(",")
      peoples_email_array = params[:people_email].split(",")
      peoples_email_array.each do |p_email|
        user = User.find(:first, :conditions=>["email = ?", p_email])
        if(user)
          profile = Profile.find(:first, :conditions=>["user_id = ?", user.id])
          peoples_array.push(profile.id)
        else
          @user =  User.create(
            :email => p_email, 
            :password => Devise.friendly_token[0,20], 
            :confirmed_at => DateTime.now
          )
          if @user.save!
            @profile = Profile.create(
              :user_id => @user.id, 
              :school_id => @course.school_id,
              :name => @user.email, 
              :full_name => @user.email
            )
            if @profile.save!
              peoples_array.push(@profile.id)
            end
          end
        end
      end
      
      # Participant record for student (looping on coming people_id)
      peoples_array.each do |p_id|
        participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Course' AND profile_id = ?", @course.id, p_id])
        if !participant
          @participant = Participant.new
          @participant.object_id = @course.id
          @participant.object_type = "Course"
          @participant.profile_id = p_id
          @participant.profile_type = "S"
          @participant.save
        end
      end
    end
    
    render :text => {"course"=>@course}.to_json
  end
  
end
