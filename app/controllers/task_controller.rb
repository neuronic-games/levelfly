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
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/task/list"
        else
          render
        end
      end
    end
  end
  
  def new
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
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
    #@outcomes = Outcome.find(:all, :include=>[:outcome_tasks], :conditions =>["outcome_tasks.task_id = ?", @task.id], :order => "name")
    @outcomes = Outcome.find(:all, :conditions =>["course_id = ?", @task.course_id], :order => "name")
    @courses = Course.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.profile_id = ? and participants.profile_type = ?", @profile.id, 'M']
    )
    @people = Participant.find(
      :all, 
      :include => [:profile], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'S'", @task.course_id]
    )
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
      if params[:outcomes] && !params[:outcomes].empty?
        OutcomeTask.delete_all(["outcome_id NOT IN (?) AND task_id = ?", params[:outcomes], @task.id])
        outcomes_array = params[:outcomes].split(",")
        outcomes_array.each do |o|
            outcome_task = OutcomeTask.find(:first, :conditions => ["task_id = ? AND outcome_id = ?", @task.id, o])
            if !outcome_task
              #OutcomeTask record
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
      
      if params[:people_id] && !params[:people_id].empty?
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
      end
      status = true
    end
    render :text => {"status"=>status, "task"=>@task}.to_json
  end
  
  def create
  end
  
  def edit
  end
  
  def duplicate
    if params[:id] && !params[:id].empty?
      @task = Task.find(params[:id])
      @dup_task = Task.new
      @dup_task.name = "#{@task.name} Copy"
      @dup_task.descr = @task.descr
      @dup_task.due_date = @task.due_date
      @dup_task.level = @task.level
      @dup_task.school_id = @task.school_id
      @dup_task.course_id = @task.course_id
      @dup_task.category_id = @task.category_id
      if @dup_task.save
        #Outcome tasks duplicate
        @task.outcome_tasks.each do |o_t|
          @dup_task_outcome = OutcomeTask.new
          @dup_task_outcome.task_id = @dup_task.id
          @dup_task_outcome.outcome_id = o_t.outcome_id
          @dup_task_outcome.points_percentage = o_t.points_percentage
          @dup_task_outcome.save
        end
        #Participant duplicate
        @task.participants.each do |p|
          @dup_task_participant = Participant.new
          @dup_task_participant.object_id = @dup_task.id
          @dup_task_participant.object_type = p.object_type
          @dup_task_participant.profile_id = p.profile_id
          @dup_task_participant.profile_type = p.profile_type
          @dup_task_participant.save
        end
      end
    end
    render :nothing => true
  end
  
  def upload_resource 
    school_id = params[:school_id]
    task_id = params[:task_id]
    @vault = Vault.find(:first, :conditions => ["object_id = ? and object_type = 'School' and vault_type = 'AWS S3'", school_id])
    if @vault
      ENV['S3_KEY']  = @vault.account
      ENV['S3_SECR'] = @vault.secret
      ENV['S3_BUCK'] = @vault.folder
      @attachment = Attachment.new(:resource=>params[:file],:object_type=>"task",:object_id=>task_id)
      @attachment.save
    end
     render :text => {"attachment"=>@attachment}.to_json
    #render :nothing => true
  end
  
  def remove_attachment
    if params[:attachment_id] && !params[:attachment_id].empty?
      @attachment = Attachment.find(params[:attachment_id])
      if @attachment
        @attachment.resource.destroy
        @attachment.destroy
      end
    end
    render :text => {"status"=>status, "attachment_id"=>@attachment.id}.to_json
  end
  
  def course_categories
    if !params[:course_id].nil?
      @categories = Category.find(:all, :conditions=>["course_id = ?", params[:course_id]])
      render :partial => "/task/course_categories", :locals=>{:categories=>@categories}
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
      @people = Participant.find(
        :all, 
        :include => [:profile], 
        :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'S'", params[:course_id]]
      )
      #@people = Profile.find(:all, :joins=>"INNER JOIN participants ON participants.object_id = #{params[:course_id]} AND participants.object_type = 'Course' AND participants.profile_id = profiles.id AND participants.profile_type = 'S' AND participants.profile_id != #{current_user.id}")
      render :partial => "/task/course_peoples"
    end
  end
  
end
