class TaskController < ApplicationController
  layout 'teacher'
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
    if params[:id] && !params[:id].empty?
      @task = Task.find(params[:id])
    else
      # Save a new task
      @task = Task.new
      @task.name = params[:task]
      @task.descr = params[:descr]
      @task.due_date = params[:due_date]
    end
    
    if @task.save
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
