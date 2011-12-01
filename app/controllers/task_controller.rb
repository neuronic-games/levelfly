class TaskController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!
  
  def index
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    
    @tasks = Task.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.profile_id = ?", @profile.id]
    )
    if request.xhr?
      render :partial => "/task/list"
    end
  end
  
  def new
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    @outcomes = Outcome.find(:all, :order => "name")
    @courses = Course.find(:all, 
      :include => [:participants], 
      :conditions => ["participants.profile_id = ? and participants.profile_type = ?", @profile.id, 'M'])
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/task/form"
        else
          render
        end
      end
    end
  end

  def show
    @task = Task.find_by_id(params[:id])
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    @outcomes = Outcome.find(:all, :order => "name")
    @courses = Course.find(:all, 
      :include => [:participants], 
      :conditions => ["participants.profile_id = ? and participants.profile_type = ?", @profile.id, 'M'])
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/task/form"
        else
          render
        end
      end
    end
  end
  
  def save
    status = false
    
    if params[:id] && !params[:id].empty?
      @task = Task.find(params[:id])
    else
      # Save a new task
      @task = Task.new
    end
    
    @task.name = params[:task]
    @task.descr = params[:descr]
    @task.due_date = params[:due_date]
    @task.level = params[:level]
    @task.school_id = params[:school_id]
    @task.course_id = params[:course_id]
    @task.category_id = params[:category_id]
    
    if @task.save
      if !params[:outcomes].empty?
        outcomes_array = params[:outcomes].split(",")
        outcomes_array.each do |o|
            outcome_task = OutcomeTask.find(:first, :conditions => ["task_id = ? AND outcome_id = ?", @task.id, o])
            if !outcome_task
              # OutcomeTask record
              @outcome_task = OutcomeTask.new
              @outcome_task.task_id = @task.id
              @outcome_task.outcome_id = o
              #@outcome_task.points_percentage = params[:points]
              @outcome_task.save
            end
        end
      end
      # Participant record
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Task' AND profile_id = ?", @task.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.object_id = @task.id
        @participant.object_type = "Task"
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
              :school_id => @task.school_id,
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
        participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Task' AND profile_id = ?", @task.id, p_id])
        if !participant
          @participant = Participant.new
          @participant.object_id = @task.id
          @participant.object_type = "Task"
          @participant.profile_id = p_id
          @participant.profile_type = "S"
          @participant.save
        end
      end
      
      status = true
    end
    
    render :text => {"status"=>status, "task"=>@task}.to_json
  end
  
  def create
  end
  
  def edit
  end
  
  def upload_resource 
    tmp = params[:file]
    require 'fileutils'
    file = File.join("public/resources", params[:name])
    FileUtils.cp tmp.path, file
    render :nothing => true
  end
  
  def course_categories
    if !params[:course_id].nil?
      @categories = Category.find(:all, :conditions=>["course_id = ?", params[:course_id]])
      render :partial => "/task/course_categories"
    end
  end
  
  def course_outcomes
    if !params[:course_id].nil?
      @outcomes = Outcome.find(:all, :conditions=>["course_id = ?", params[:course_id]])
      render :partial => "/task/course_outcomes"
    end
  end
  
  def course_peoples
    if !params[:course_id].nil?
      @people = Profile.find(:all, :joins=>"INNER JOIN participants ON participants.object_id = #{params[:course_id]} AND participants.object_type = 'Course' AND participants.profile_id = profiles.id AND participants.profile_type = 'S' AND participants.profile_id != #{current_user.id}")
      render :partial => "/task/course_peoples"
    end
  end
  
end
