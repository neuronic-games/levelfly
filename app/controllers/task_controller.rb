class TaskController < ApplicationController
  layout 'teacher'
  before_filter :authenticate_user!
  
  def index
    @outcomes = Outcome.find(:all, 
      :order => "name")
      
    @participants = Participant.find(:all,  
      :order => "object_type")
  end

  def show
  end
  
  def save
    status = false
    
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if @profile
      user_session[:profile_id] = @profile.id
    end
    
    if params[:id] && !params[:id].empty?
      @task = Task.find(params[:id])
    else
      # Save a new task
      @task = Task.new
    end
    
    @task.name = params[:task]
    @task.descr = params[:descr]
    @task.due_date = params[:due_date]
    
    if @task.save
      if !params[:outcomes].empty?
        outcomes_array = params[:outcomes].split(",")
        outcomes_array.each do |o|
          if o != ""
            @outcome = Outcome.find_by_name(o)
            if(!@outcome)
              @outcome = Outcome.new
              @outcome.name = o
              @outcome.save
            end
            outcome_task = OutcomeTask.find(:first, :conditions => ["task_id = ? AND outcome_id = ?", @task.id, @outcome.id])
            if !outcome_task
              # OutcomeTask record
              @outcome_task = OutcomeTask.new
              @outcome_task.task_id = @task.id
              @outcome_task.outcome_id = @outcome.id
              @outcome_task.points_percentage = params[:points]
              @outcome_task.save
            end
          end
        end
      end
      # Participant record
      participant = Participant.find(:first, :conditions => ["object_id = ? AND profile_id = ?", @task.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.object_id = @task.id
        @participant.object_type = "Task"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        @participant.save
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
end
