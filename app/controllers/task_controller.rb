class TaskController < ApplicationController
  include TaskHelper

  layout 'main'
  before_filter :authenticate_user!
  before_filter :check_role,:only=>[:new, :save]
  
  def index
    @tasks = []
    @profile = current_profile
    if @profile
      @courses = Course.find(
        :all,
        :select => "distinct *",
        :include => [:participants],
        :conditions => ["participants.profile_id = ? AND parent_type = ? AND participants.profile_type != ? AND courses.archived = ? AND courses.removed = ? ", @profile.id, Course.parent_type_course, Course.profile_type_pending, false, false],
        :order => 'name'
      )

      if params[:search_text]
        search_text =  "%#{params[:search_text]}%"
        @tasks = Task.search_tasks(@profile.id, search_text, params[:filter], params[:course_id])
        search_render = true
      else
        # Check if the user was working on a details page before, and redirect if so
        return if redirect_to_last_action(@profile, 'task', '/task/show')
        @tasks = Task.filter_by(@profile.id, params[:course_id], "current")
      end
    end

    respond_to do |wants|
      wants.html do
        if request.xhr?
          if search_render
            render :partial => "/task/task_list" #, :locals => {:t=>@tasks}
          else
            render :partial => "/task/list"
          end
        else
          render
        end
      end
    end
  end

  def new
    @profile = current_profile
    @no_course = Course.find_by_code('') || Course.find_by_code(nil)

    @courses = Course.find(
      :all,
      :include => [:participants],
      :conditions => ["participants.profile_id = ? and participants.profile_type = ? and parent_type = ? and courses.archived = ? and courses.removed = ?", @profile.id, 'M',Course.parent_type_course,false, false]
    )
    @task = Task.new
    respond_to do |wants|
      wants.html do
        if request.xhr?
          render :partial => "/task/form" ,:locals=>{:task_new => true, :course_id => params[:course_id]}
        else
          render
        end
      end
    end
  end


   def outcome_unchecked
    status = false
    if params[:task_id] && !params[:task_id].blank?
      outcome_task = OutcomeTask.find(:first, :conditions=>["outcome_id = ? AND task_id = ?", params[:outcome_id], params[:task_id]])
      if outcome_task
        outcome_task.destroy
        status = true
      end
    end
    render :text => {"status"=>status}.to_json
  end

  def show
    @task = Task.find_by_id(params[:id])
    @course = @task.course
    @profile = current_profile
    @no_course = Course.find_by_code('') ||Course.find_by_code(nil)
		## Below query seems wrong as it is taking profile_id as a check but if we take current users profile_id then it
		## will always return current users record only (if the current user is a task owner) It may be written to check if the
		## current user is the task owner or not. I am (Vaibhav) now commenting this and will impose a new boolean  check to see
		## if the current user is task owner or not
		#@task_owner =  TaskParticipant.find(:first, :conditions=>["profile_id = ? and task_id = ? and profile_type = ?",@profile.id, @task.id, Task.profile_type_owner])
		@is_task_owner = false
		@task_owner = @task.task_owner
		if @task_owner.id == @profile.id
			@is_task_owner = true
			@files = @task.attachments.order("starred desc")
		else
			@files = @task.attachments.where("owner_id IN (?)", [@profile.id, @task_owner.id]).order("starred desc")
		end
    all_tasks = Task.filter_by(@course.owner.id,@course.id,"").collect(&:points)
    @tasks_created = all_tasks.count
    @allocated_points = all_tasks.sum
    @remaining_points = 1000 - @allocated_points
    @outcomes = @course.outcomes.order('name') if @course
    @courses = Course.find(
      :all,
      :include => [:participants],
      :conditions => ["participants.profile_id = ? and participants.profile_type = ? and parent_type = ? and courses.archived = ? AND courses.removed = ?", @profile.id, 'M',Course.parent_type_course,false, false]
    )

    @groups = Group.find(:all, :conditions =>["task_id = ?", @task.id])

    @people = Participant.find(
      :all,
      :include => [:profile => :user],
      :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'S' AND users.status != 'D'", @task.course_id],
      :order => "profiles.full_name"
    )
    @task_members = TaskParticipant.find(
      :all,
      :include => [:profile => :user],
      :conditions => ["task_participants.task_id = ? AND task_participants.profile_type = 'M' AND users.status != 'D'", @task.id],
      :order => "profiles.full_name"
    )

    participant = TaskParticipant.find(:first,
      :include => [:profile, :task],
      :conditions => ["task_id = ? and profile_id = ?", @task.id, @profile.id])
    @check_complete_task = true if participant and participant.status == Task.status_complete

    @profile.record_action('last', 'task')
    @profile.record_action('task', @task.id)

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

  def get_task
    @profile = current_profile
    tasks = Task.filter_by(@profile.id, params[:show], params[:filter])
    logger.info tasks
    puts "!!!!!!!!!!!!!"
    puts params.inspect
    render :partial => "/task/task_list", :locals => {:@tasks =>tasks}
  end

  def check_priorities
    status = false
    if params[:task_id] && !params[:task_id].empty?
       @task = TaskParticipant.find(:first,:conditions=>["task_id =?",params[:task_id]])
        if @task
          if params[:priority] == "L"
            @task.priority = "H"
            @task.save
          else
            @task.priority = "L"
            @task.save
          end
        end
        status = true
    end
    render :text => { :status => status, :priority => @task.priority }.to_json
  end

  def toggle_priority
    status = false
    @task = TaskParticipant.find(:first, :conditions => ["task_id = ? and profile_id = ?", params[:task_id], user_session[:profile_id]])
    if @task
      @task.priority = (@task.priority == "L" ? "H" : "L")
      @task.save
      status = true
    end
    render :text => { :status => status, :priority => @task.priority }.to_json
  end

  def save
    status = false
    category_name = ""
    if params[:id] && !params[:id].empty?
      @task = Task.find(params[:id])
    else
      # Save a new task
      @task = Task.new
    end
    course = @task.course_id ? @task.course_id : 0

    @profile = Profile.find(user_session[:profile_id])
    @task.name = params[:task].slice(0,64) if params[:task]
    @task.descr = params[:descr] if params[:descr]
    @task.due_date = Date.strptime(params[:due_date], '%m-%d-%Y') if params[:due_date] && params[:due_date] != "null"
    @task.points = params[:task_xp] if params[:task_xp]
    @task.school_id = params[:school_id] if params[:school_id]
    @task.course_id = params[:course_id] if params[:course_id]
    @task.archived = false
    @task.category_id = params[:category_id] if params[:category_id]
    @task.extra_credit = params[:extra_credit] if params[:extra_credit]
    @task.all_members = true if (params[:all_members] == "All Members")
    @task.all_members = false if (params[:all_members] == "Some")
    # Has something changed on the task that could change it's points value?
    # FIXME: We may want to recalculate points if the task raiting or course settings change

    if params[:file]
      @task.image.destroy if @task.image
      @task.image = params[:file]
    end

    if course != 0 && course != @task.course_id && @task.image.to_s != "/images/original/missing.png"
      school_id = @task.school_id ? @task.school_id : 1
      filename = @task.image_file_name
      bucket = "#{ENV['S3_PATH']}/schools/#{school_id}/courses/#{course}/tasks/#{@task.id}"
      data = Attachment.aws_get_file_data(school_id, filename, bucket)
      bucket_2 = "#{ENV['S3_PATH']}/schools/#{school_id}/courses/#{@task.course_id}/tasks/#{@task.id}"
      Attachment.aws_upload_base64(school_id, bucket_2, filename, data)
      Attachment.aws_delete_file(school_id, filename, bucket)
    end

    if @task.course_id != 0 && @task.image.to_s == "/images/original/missing.png"
      @task.image = @task.course.image if @task.course.image_file_name.present?
    end

    if @task.save
      #get wall id
      wall_id = Wall.get_wall_id(@task.id,"Task")
      if params[:outcomes] && !params[:outcomes].empty?
        outcome_ids = params[:outcomes].split(",")
        #OutcomeTask.delete_all(["outcome_id NOT IN (?) AND task_id = ?", outcome_ids, @task.id])
        OutcomeTask.destroy_all(["outcome_id is NULL AND task_id = ?", @task.id])
        outcomes_array = params[:outcomes].split(",")
        outcomes_array.each do |o|
          if o !=""
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
      end
      # Participant record
      course_participants = Participant.all( :joins => [:profile], :conditions => ["participants.target_id=? AND participants.profile_type = 'S' AND target_type = 'Course'",params[:course_id] && params[:course_id] != "" && params[:course_id] != "null"  ? params[:course_id] : 0 ],:select => ["profiles.full_name,participants.id,participants.profile_id"], :order => "full_name")
      task_participant = TaskParticipant.find(:first, :conditions => ["task_id = ? AND profile_type='O' AND profile_id = ?", @task.id, user_session[:profile_id]])
      if !task_participant
        @task_participant = TaskParticipant.new
        @task_participant.profile_id = user_session[:profile_id]
        @task_participant.profile_type = "O"
        @task_participant.status = "A"
        @task_participant.priority = "L"
        @task_participant.task_id = @task.id
        if @task_participant.save
          Feed.create(
            :profile_id => user_session[:profile_id],
            :wall_id =>wall_id
          )
        end
      end
      if params[:remove_people_ids] && !params[:remove_people_ids].empty?
        remove_people = params[:remove_people_ids].split(",")
        remove_participants = TaskParticipant.find(:all,:conditions => ["task_id = ? and profile_type = 'M' and profile_id in (?)",@task.id,remove_people])
        remove_participants.each do |participant|
          status = Task.points_to_student(@task.id, false, participant.profile_id,user_session[:profile_id])
          participant.delete
        end
      end
      peoples_array=[]
      if params[:people_id] && !params[:people_id].empty?
        if params[:people_id] == "all_people"
          @task.all_members = false
          @task.save
        else
          peoples_array = params[:people_id].split(",")
          peoples_array.each do |p_id|
            if p_id !=""
              task_participant = TaskParticipant.find(:first, :conditions => ["task_id = ? AND profile_type='M' AND profile_id = ?", @task.id, p_id])
              if !task_participant
                @task_participant = TaskParticipant.new
                @task_participant.profile_id = p_id
                @task_participant.profile_type = "M"
                @task_participant.status = "A"
                @task_participant.priority = "L"
                @task_participant.task_id = @task.id
                if @task_participant.save
                  Feed.create(
                    :profile_id => p_id,
                    :wall_id => wall_id
                  )
                content = "#{@profile.full_name} assigned you a new task: #{@task.name}"
                Message.send_notification(@profile.id,content,p_id)
                end
              end
            end
          end
        end
      end
      status = true
      image_url = params[:file] ? @task.image.url : ""
      @task_outcomes = @task.outcomes
      if params[:category_id] and !params[:category_id].blank? and params[:category_id] !="null" and params[:category_id] !="undefined"
        c = Category.find(:first, :select=>"name", :conditions=>["id = ?",params[:category_id]])
        if c and !c.nil?
          category_name= c.name
        end
      end
    end
    render :text => {"status"=>status, "task"=>@task, "image_url"=>image_url, "participants"=>course_participants, "outcomes"=> @task_outcomes, "category_name"=>category_name}.to_json
  end

  def create
  end

  def view_setup
    @task = Task.find_by_id(params[:id])
    render :partial => "/task/setup",:locals=>{:task=>@task}
  end

  def remove_tasks
    if params[:task_id] && !params[:task_id].empty?
       @task = Task.find(params[:task_id])
       task_participant=TaskParticipant.find(:first,:conditions => ["task_id = ? and profile_id = ?",@task.id,user_session[:profile_id]])
       if task_participant.profile_type == "O"
         @task.archived = true
         modify_xp(params[:task_id],false)
       else
         task_participant.delete
       end
       @task.save
       render :text => {:status=>true}.to_json
    end
  end

  def task_complete
    status = nil
    if params[:task_id] && !params[:task_id].empty?
      status = Task.complete_task(params[:task_id], params[:check_val]=="true", user_session[:profile_id])
    end
    render :text => {:status => status}.to_json
  end

  def points_credit
    if params[:task_id] && !params[:task_id].nil?
      if params[:member_ids] && !params[:member_ids].nil?
        params[:member_ids].each do |member_id|
          status = Task.points_to_student(params[:task_id], params[:check_val]=="true", member_id,user_session[:profile_id])
        end
        task = Task.find(params[:task_id])
        task_points = task.points if task
        render :text => {:status => status, :task_points => task_points}.to_json
      else
        task_participants = TaskParticipant.find(:all,:conditions => ["task_id = ? and profile_type = 'M'",params[:task_id]])
        task_participants.each do |participant|
          status = Task.points_to_student(params[:task_id], params[:check_val]=="true", participant.profile_id,user_session[:profile_id])
        end
        task = Task.find(params[:task_id])
        task_points = task.points if task
        render :text => {:status => status, :task_points => task_points}.to_json
      end
    end
  end

  def extra_credit
    if params[:task_id] && !params[:task_id].nil?
      status = nil;
      @profile = Profile.find(params[:member_id])
      @task = Task.find(params[:task_id])
      @tp = TaskParticipant.find(:first, :conditions=>["profile_id = ? and task_id = ?",params[:member_id],params[:task_id]])
      if @tp and !@tp.nil?
        @tp.update_attribute("extra_credit",params[:check_val])
        status = params[:check_val]
        @profile.xp += status ? @task.points/10 : -@task.points/10
        @profile.save
      end
    end
    render :text => {:status => status}.to_json
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
          @dup_task_participant.target_id = @dup_task.id
          @dup_task_participant.target_type = p.target_type
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
    task_id = params[:id]
    #@vault = Vault.find(:first, :conditions => ["object_id = ? and object_type = 'School' and vault_type = 'AWS S3'", school_id])
    #if @vault
      @attachment = Attachment.new(:resource=>params[:file], :school_id=>school_id, :target_type=>"task", :target_id=>task_id)
      if @attachment.save
        @url = @attachment.resource.url
        render :text => {"attachment"=>@attachment, "resource_url" => @url}.to_json
      else
        render :nothing => true
      end
    #end
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
      @course = Course.find(params[:course_id])
      @outcomes = @course ? @course.outcomes.order('name') : nil
      render :partial => "/task/course_outcomes"
    end
  end

  def course_peoples
    if !params[:course_id].nil?
      @course = Course.find(params[:course_id])
      @people = Participant.find(
        :all,
        :include => [:profile => :user],
        :conditions => ["participants.target_id = ? AND participants.target_type='Course' AND participants.profile_type = 'S' AND users.status != 'D'", params[:course_id]],
        :order => "profiles.full_name"
      )
      all_tasks = []
      if @course.owner
        Task.filter_by(@course.owner.id,@course.id,"").collect(&:points)
      end
      @tasks_created = all_tasks.count
      @allocated_points = all_tasks.sum
      @remaining_points = 1000 - @allocated_points
      render :partial => "/task/course_peoples"
    end
  end

  def view_task
    @profile = current_profile
    @courses = Course.find(
        :all,
        :select => "distinct *",
        :include => [:participants],
        :conditions => ["participants.profile_id = ? AND parent_type = ? AND participants.profile_type != ? AND courses.archived = ?", @profile.id, Course.parent_type_course, Course.profile_type_pending, false],
        :order => 'name'
      )
    @tasks = Task.filter_by(@profile.id, params[:course_id], "current")
    render :partial => "/task/list", :locals=>{:tasks=>@tasks,:course_id=>params[:course_id]}
  end

   def remove_task
    if params[:task_id] && !params[:task_id].empty?
       @task = Task.find(params[:task_id])
       @task.archived = true
       @task.save
       modify_xp(params[:task_id],false)
       render :text => {:status=>true}.to_json
    end
  end

  def check_role
    if Role.check_permission(user_session[:profile_id],"T")==false
       render :text=>""
    end
  end

  private

  def modify_xp(task_id,complete)
    task_participants = TaskParticipant.find(:all,:conditions => ["task_id = ? and profile_type = 'M'",task_id])
      task_participants.each do |participant|
        status = Task.points_to_student(task_id, complete, participant.profile_id,user_session[:profile_id])
        participant.delete
      end
  end

end
