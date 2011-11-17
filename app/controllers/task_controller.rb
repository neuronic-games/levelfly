class TaskController < ApplicationController
  layout 'teacher'
  def index
  end

  def show
  end
  
  def save
    status = false
    if params[:id]
      #TO DO
    else
      # Save a new profile
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
end
