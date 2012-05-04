class CourseController < ApplicationController
  layout 'main'
  before_filter :authenticate_user!

  def index
    @profile = Profile.find(:first, :conditions => ["user_id = ?", current_user.id])
    if params[:search_text]
      search_text =  "#{params[:search_text]}%"
      @courses = Course.find(
        :all,
        :include => [:participants], 
        :conditions => ["participants.profile_id = ? AND (courses.name LIKE ? OR courses.code LIKE ?)", @profile.id, search_text,  search_text]
      )
    else
      if @profile
        user_session[:profile_id] = @profile.id
        user_session[:profile_name] = @profile.full_name
        user_session[:profile_major] = @profile.major.name if @profile.major
        user_session[:profile_school] = @profile.school.code if @profile.school
        user_session[:vault] = @profile.school.vaults[0].folder if @profile.school
        #Set AWS credentials
        # set_aws_vault(@profile.school.vaults[0]) if @profile.school
      end
      
      @courses = Course.find(
        :all, 
        :include => [:participants], 
        :conditions => ["participants.profile_id = ?", @profile.id]
      )
    end  
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
    @wall = Wall.find(:first,:conditions=>["parent_id = ? AND parent_type='Course'", @course.id])
    @peoples = Profile.find(
      :all, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'S'", @course.id]
    )
    @courseMaster = Profile.find(
      :first, 
      :include => [:participants], 
      :conditions => ["participants.object_id = ? AND participants.object_type='Course' AND participants.profile_type = 'M'", @course.id]
      )
    @totaltask = Task.find(:all, :conditions =>["course_id = ?",@course.id])
    @groups = Group.find(:all, :conditions=>["course_id = ?",@course.id])
    @course_owner = Participant.find(:first, :conditions=>["object_id = ? AND profile_type = 'M' AND object_type='Course'",params[:id]])
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
    
    @course.name = params[:course] if params[:course]
    @course.descr = params[:descr] if params[:descr]
    @course.code = params[:code] if params[:code]
    @course.section = params[:section] if params[:section]
    @course.school_id = params[:school_id] if params[:school_id]
    @course.rating_low = params[:rating_low] if params[:rating_low]
    @course.rating_medium = params[:rating_medium] if params[:rating_medium]
    @course.rating_high = params[:rating_high] if params[:rating_high]
    @course.tasks_low = params[:task_low] if params[:task_low]
    @course.tasks_medium = params[:task_medium] if params[:task_medium]
    @course.tasks_high = params[:task_high] if params[:task_high]
           
    if params[:file]
      @course.image.destroy if @course.image
      @course.image = params[:file]
    end
    
    if @course.save
      #get wall id
      wall_id = Wall.get_wall_id(@course.id,"Course")
      #Save categories
      if params[:categories] && !params[:categories].empty?
        categories_array = params[:categories].split(",")
        loaded_categories_array = params[:percent_value].split(",")
        categories_array.each_with_index do |category,i|
          @category = Category.create(
            :name=> category,
            :percent_value=> loaded_categories_array[i],
            :course_id=> @course.id,
            :school_id=> @course.school_id
          )
        end
      end
      
      #Save outcomes
      if params[:outcomes] && !params[:outcomes].empty?
        outcomes_array = params[:outcomes].split(",")
        outcomes_descs_array = params[:outcomes_descr].split(",")
        outcomes_array.each_with_index do |outcome,i|
          @outcome = Outcome.create(
            :name=> outcome,
            :descr=> outcomes_descs_array[i],
            :course_id=> @course.id,
            :school_id=> @course.school_id
          )
        end
      end
      
      # Participant record for master
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Course' AND profile_id = ?", @course.id, user_session[:profile_id]])
      if !participant
        @participant = Participant.new
        @participant.object_id = @course.id
        @participant.object_type = "Course"
        @participant.profile_id = user_session[:profile_id]
        @participant.profile_type = "M"
        if @participant.save
          Feed.create(
            :profile_id => user_session[:profile_id],
            :wall_id =>wall_id
          )
        end
      end
      image_url = params[:file] ? @course.image.url : ""
    end
    render :text => {"course"=>@course, "image_url"=>image_url}.to_json
  end
  
   def get_participants
    search_participants()
   end
  
  def add_participant
    status = false
    already_added = false
    if params[:profile_id] && params[:course_id]
      participant_exist = Participant.find(:first, :conditions => ["object_id = ? AND object_type='Course' AND profile_id = ?", params[:course_id], params[:profile_id]])
      if !participant_exist
        @participant = Participant.new
        @participant.object_id = params[:course_id]
        @participant.object_type = "Course"
        @participant.profile_id = params[:profile_id]
        @participant.profile_type = "S"
        if @participant.save
          wall_id = Wall.get_wall_id(params[:course_id],"Course")
          Feed.create(
            :profile_id => params[:profile_id],
            :wall_id =>wall_id
          )
          status = true
        end
      else 
          already_added = true
      end
    end
    render :text => {"status"=>status, "already_added" => already_added}.to_json
  end
  
  def delete_participant
    status = false
    if params[:profile_id] && params[:course_id]
      participant = Participant.find(:first, :conditions => ["object_id = ? AND object_type = 'Course' AND profile_id = ? ", params[:course_id], params[:profile_id]]) 
      if participant
        participant.delete
        status = true
      end
    end
    render :text => {"status"=>status}.to_json
  end
  
  def remove_course_outcomes
    if params[:outcomes] && !params[:outcomes].nil?
      outcome_array = params[:outcomes].split(',')
      Outcome.destroy(outcome_array)
      render :text => {"status"=>"true"}.to_json
    end
  end
  
  def update_course_outcomes
    if params[:outcome_id] && !params[:outcome_id].empty?
      outcome = Outcome.find(params[:outcome_id])
      outcome.name = params[:outcome] if params[:outcome] && !params[:outcome].empty?
      outcome.save
    end
    render :nothing =>true
  end
  
  def update_course_categories
    if params[:category_id] && !params[:category_id].empty?
      category = Category.find(params[:category_id])
      category.name = params[:category] if params[:category] && !params[:category].empty?
      category.save
    end
    render :nothing =>true
  end
  
  def remove_course_categories
    if params[:categories] && !params[:categories].nil?
      category_array = params[:categories].split(',')
      Category.destroy(category_array)
      render :text => {"status"=>"true"}.to_json
    end
  end
  
  def send_email
      if params[:user] && !params[:user].nil?
        UserMailer.registration_confirmation(params[:user]).deliver
        render :text=> "Mail send successfully!!"
      end
  end
  
  def add_file
    school_id = params[:school_id]
    task_id = params[:id]
    @vault = Vault.find(:first, :conditions => ["object_id = ? and object_type = 'School' and vault_type = 'AWS S3'", school_id])
    if @vault
      @attachment = Attachment.new(:resource=>params[:file], :school_id=>school_id, :object_type=>"Task", :object_id=>task_id)
      if @attachment.save
        @url = @attachment.resource.url
        render :text => {"attachment" => @attachment, "resource_url" => @url}.to_json
      else
        render :nothing => true
      end
    end
  end
  
end